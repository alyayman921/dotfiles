#!/usr/bin/env python3
"""
Video Batch Converter - PyQt6 application for ffmpeg-based video conversion
Supports AV1, H.265, and Editing Proxies (DNxHR/ProRes)
"""

import sys
import os
import json
import subprocess
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, Dict, List
from datetime import datetime

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QComboBox, QSpinBox, QFileDialog, QTextEdit,
    QMessageBox, QDialog, QLineEdit, QListWidget, QGroupBox, QGridLayout
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtGui import QFont

CONFIG_DIR = Path.home() / ".video_converter"
CONFIG_FILE = CONFIG_DIR / "presets.json"

# Added Editing Codecs for DaVinci Resolve Linux support
CODECS = ["libsvtav1", "libx265", "dnxhr_lb", "prores_proxy", "mpeg4"]
AUDIO_CODECS = ["libopus", "libmp3lame", "pcm_s16le"]

@dataclass
class ConversionPreset:
    name: str
    codec: str
    crf: int
    fps: int
    audio_codec: str
    folder_path: str

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "codec": self.codec,
            "crf": self.crf,
            "fps": self.fps,
            "audio_codec": self.audio_codec,
            "folder_path": self.folder_path,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "ConversionPreset":
        return cls(**data)

class PresetManager:
    def __init__(self):
        CONFIG_DIR.mkdir(parents=True, exist_ok=True)

    def save_presets(self, presets: Dict[str, ConversionPreset]):
        data = {name: preset.to_dict() for name, preset in presets.items()}
        with open(CONFIG_FILE, "w") as f:
            json.dump(data, f, indent=2)

    def load_presets(self) -> Dict[str, ConversionPreset]:
        if not CONFIG_FILE.exists():
            return {}
        with open(CONFIG_FILE, "r") as f:
            data = json.load(f)
        return {name: ConversionPreset.from_dict(preset) for name, preset in data.items()}

    def get_folder_preset(self, folder_path: str) -> Optional[ConversionPreset]:
        local_preset = self.load_local_preset(folder_path)
        if local_preset: return local_preset

        presets = self.load_presets()
        for preset in presets.values():
            if preset.folder_path == folder_path:
                return preset
        return None

    def save_folder_preset(self, preset: ConversionPreset):
        self.save_local_preset(preset)
        presets = self.load_presets()
        presets[preset.name] = preset
        self.save_presets(presets)

    @staticmethod
    def load_local_preset(folder_path: str) -> Optional[ConversionPreset]:
        config_file = Path(folder_path) / ".converter_config.json"
        if config_file.exists():
            try:
                with open(config_file, "r") as f:
                    data = json.load(f)
                return ConversionPreset.from_dict(data)
            except Exception:
                return None
        return None

    @staticmethod
    def save_local_preset(preset: ConversionPreset):
        config_file = Path(preset.folder_path) / ".converter_config.json"
        try:
            with open(config_file, "w") as f:
                json.dump(preset.to_dict(), f, indent=2)
        except Exception:
            pass

class FFmpegConverter:
    @staticmethod
    def get_video_files(folder_path: str) -> List[str]:
        video_extensions = {".mp4", ".mkv", ".avi", ".mov", ".flv", ".wmv", ".webm"}
        folder = Path(folder_path)
        return sorted([str(f) for f in folder.glob("*") if f.is_file() and f.suffix.lower() in video_extensions])

    @staticmethod
    def build_command(input_file: str, codec: str, crf: int, fps: int, audio_codec: str) -> str:
        input_path = Path(input_file)

        # Default Logic
        output_ext = ".mp4"
        video_params = f"-c:v libx265 -crf {crf}"
        pix_fmt = ""

        if codec == "libsvtav1":
            output_ext = ".mkv"
            video_params = f"-c:v libsvtav1 -preset 6 -crf {crf}"

        elif codec == "dnxhr_lb":
            output_ext = ".mov"
            # DNxHR LB requires specific pixel format for Resolve
            video_params = "-c:v dnxhd -profile:v dnxhr_lb"
            pix_fmt = "-pix_fmt yuv422p"
            # Force audio to PCM for DNxHR if set to automatic/default
            if audio_codec == "libopus": audio_codec = "pcm_s16le"

        elif codec == "prores_proxy":
            output_ext = ".mov"
            video_params = "-c:v prores_ks -profile:v 0"
            if audio_codec == "libopus": audio_codec = "pcm_s16le"

        elif codec == "mpeg4":
            output_ext = ".mp4"
            video_params = f"-c:v mpeg4 -q:v {max(1, int(crf/2))}"

        output_path = input_path.parent / f"{input_path.stem}_converted{output_ext}"

        cmd = (
            f'ffmpeg -i "{input_file}" '
            f'{video_params} {pix_fmt} '
            f'-r {fps} '
            f'-c:a {audio_codec} '
            f'"{str(output_path.absolute())}" -y'
        )
        return cmd

    @staticmethod
    def run_conversion(input_file: str, codec: str, crf: int, fps: int, audio_codec: str, callback=None) -> bool:
        cmd = FFmpegConverter.build_command(input_file, codec, crf, fps, audio_codec)
        try:
            process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            stdout, stderr = process.communicate()
            if process.returncode != 0:
                if callback: callback(f"Error: {stderr[:300]}")
                return False
            return True
        except Exception as e:
            if callback: callback(f"Error: {str(e)}")
            return False

class ConversionWorker(QThread):
    log_signal = pyqtSignal(str)
    finished_signal = pyqtSignal()
    error_signal = pyqtSignal(str)

    def __init__(self, video_files, codec, crf, fps, audio_codec):
        super().__init__()
        self.video_files = video_files
        self.codec = codec
        self.crf = crf
        self.fps = fps
        self.audio_codec = audio_codec
        self.is_running = True

    def run(self):
        try:
            for i, input_file in enumerate(self.video_files, 1):
                if not self.is_running: break
                filename = Path(input_file).name
                self.log_signal.emit(f"[{i}/{len(self.video_files)}] Converting: {filename}")
                success = FFmpegConverter.run_conversion(input_file, self.codec, self.crf, self.fps, self.audio_codec, self.log_signal.emit)
                self.log_signal.emit("   ✓ Done" if success else "   ❌ Failed")
            self.log_signal.emit("Batch conversion finished!")
            self.finished_signal.emit()
        except Exception as e:
            self.error_signal.emit(str(e))
            self.finished_signal.emit()

    def stop(self): self.is_running = False

# ... [SavePresetDialog and ManagePresetsDialog remain the same as your provided code] ...

class SavePresetDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Save Preset")
        self.setGeometry(100, 100, 400, 200)
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        layout.addWidget(QLabel("Give this preset a name:"))
        self.name_input = QLineEdit()
        self.name_input.setPlaceholderText("e.g., DaVinci Proxy, Archival AV1")
        layout.addWidget(self.name_input)

        btn_box = QHBoxLayout()
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.accept)
        cancel_btn = QPushButton("Cancel")
        cancel_btn.clicked.connect(self.reject)
        btn_box.addWidget(save_btn)
        btn_box.addWidget(cancel_btn)
        layout.addLayout(btn_box)
        self.setLayout(layout)

    def get_preset_name(self): return self.name_input.text().strip()

class ManagePresetsDialog(QDialog):
    def __init__(self, presets, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Manage Presets")
        self.presets = presets
        self.deleted_preset = None
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()
        self.list_widget = QListWidget()
        for name in self.presets: self.list_widget.addItem(name)
        layout.addWidget(self.list_widget)

        del_btn = QPushButton("Delete Selected")
        del_btn.clicked.connect(self.delete_item)
        layout.addWidget(del_btn)

        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
        self.setLayout(layout)

    def delete_item(self):
        item = self.list_widget.currentItem()
        if item:
            name = item.text()
            del self.presets[name]
            self.deleted_preset = name
            self.list_widget.takeItem(self.list_widget.currentRow())

class VideoConverterApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Video Batch Converter Pro")
        self.setGeometry(100, 100, 900, 850)
        self.preset_manager = PresetManager()
        self.presets = self.preset_manager.load_presets()
        self.selected_folder = ""
        self.init_ui()

    def init_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)

        # Folder Selection
        fg = QGroupBox("Target Folder")
        fl = QHBoxLayout(fg)
        self.folder_label = QLabel("Please select a folder...")
        sel_btn = QPushButton("Browse")
        sel_btn.clicked.connect(self.select_folder)
        fl.addWidget(self.folder_label, 1)
        fl.addWidget(sel_btn)
        layout.addWidget(fg)

        # Settings
        sg = QGroupBox("Encoding Parameters")
        sl = QGridLayout(sg)

        sl.addWidget(QLabel("Codec:"), 0, 0)
        self.codec_combo = QComboBox()
        self.codec_combo.addItems(CODECS)
        sl.addWidget(self.codec_combo, 0, 1)

        sl.addWidget(QLabel("Quality (CRF/Q):"), 1, 0)
        self.crf_spin = QSpinBox()
        self.crf_spin.setRange(0, 63)
        self.crf_spin.setValue(28)
        sl.addWidget(self.crf_spin, 1, 1)

        sl.addWidget(QLabel("FPS:"), 2, 0)
        self.fps_spin = QSpinBox()
        self.fps_spin.setRange(1, 120)
        self.fps_spin.setValue(30)
        sl.addWidget(self.fps_spin, 2, 1)

        sl.addWidget(QLabel("Audio:"), 3, 0)
        self.audio_combo = QComboBox()
        self.audio_combo.addItems(AUDIO_CODECS)
        sl.addWidget(self.audio_combo, 3, 1)

        layout.addWidget(sg)

        # Buttons
        bl = QHBoxLayout()
        save_p = QPushButton("Save Preset")
        save_p.clicked.connect(self.save_preset)
        manage_p = QPushButton("Manage Presets")
        manage_p.clicked.connect(self.manage_presets)
        bl.addWidget(save_p)
        bl.addWidget(manage_p)
        layout.addLayout(bl)

        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setStyleSheet("background: #1e1e1e; color: #00ff00; font-family: monospace;")
        layout.addWidget(self.log_text)

        self.start_btn = QPushButton("START CONVERSION")
        self.start_btn.setFixedHeight(50)
        self.start_btn.setStyleSheet("background: #2e7d32; color: white; font-weight: bold;")
        self.start_btn.clicked.connect(self.start_conversion)
        layout.addWidget(self.start_btn)

    def select_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.selected_folder = folder
            self.folder_label.setText(folder)
            p = self.preset_manager.get_folder_preset(folder)
            if p: self.load_preset_values(p)

    def save_preset(self):
        if not self.selected_folder: return
        d = SavePresetDialog(self)
        if d.exec():
            name = d.get_preset_name()
            p = ConversionPreset(name, self.codec_combo.currentText(), self.crf_spin.value(), self.fps_spin.value(), self.audio_combo.currentText(), self.selected_folder)
            self.preset_manager.save_folder_preset(p)
            self.presets = self.preset_manager.load_presets()

    def manage_presets(self):
        d = ManagePresetsDialog(self.presets.copy(), self)
        if d.exec():
            self.preset_manager.save_presets(d.presets)
            self.presets = self.preset_manager.load_presets()

    def load_preset_values(self, p):
        self.codec_combo.setCurrentText(p.codec)
        self.crf_spin.setValue(p.crf)
        self.fps_spin.setValue(p.fps)
        self.audio_combo.setCurrentText(p.audio_codec)

    def start_conversion(self):
        files = FFmpegConverter.get_video_files(self.selected_folder)
        if not files: return
        self.start_btn.setEnabled(False)
        self.worker = ConversionWorker(files, self.codec_combo.currentText(), self.crf_spin.value(), self.fps_spin.value(), self.audio_combo.currentText())
        self.worker.log_signal.connect(lambda m: self.log_text.append(m))
        self.worker.finished_signal.connect(lambda: self.start_btn.setEnabled(True))
        self.worker.start()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    ex = VideoConverterApp()
    ex.show()
    sys.exit(app.exec())
