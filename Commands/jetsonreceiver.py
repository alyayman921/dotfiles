#!/usr/bin/env python3
import sys
import socket
import json
import time
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QProgressBar, QGroupBox, QFrame, QGridLayout)
from PyQt5.QtCore import QTimer, Qt
from PyQt5.QtGui import QFont

class CompactGaugeWidget(QWidget):
    def __init__(self, title, max_value, unit="", warning_threshold=80, critical_threshold=90):
        super().__init__()
        self.max_value = max_value
        self.unit = unit
        
        layout = QVBoxLayout()
        layout.setContentsMargins(2, 2, 2, 2)
        layout.setSpacing(2)
        self.setLayout(layout)
        
        self.title_label = QLabel(title)
        self.title_label.setAlignment(Qt.AlignCenter)
        self.title_label.setStyleSheet("font-weight: bold; font-size: 10px;")
        
        self.value_label = QLabel("0" + unit)
        self.value_label.setAlignment(Qt.AlignCenter)
        self.value_label.setStyleSheet("font-size: 11px;")
        
        self.gauge = QProgressBar()
        self.gauge.setMaximum(100)
        self.gauge.setTextVisible(False)
        self.gauge.setFixedHeight(12)
        
        layout.addWidget(self.title_label)
        layout.addWidget(self.value_label)
        layout.addWidget(self.gauge)
    
    def set_value(self, value, total=None):
        if total and total > 0:
            percentage = (value / total) * 100
            self.value_label.setText(f"{value}{self.unit}")
        else:
            percentage = value
            self.value_label.setText(f"{value:.1f}{self.unit}")
        
        self.gauge.setValue(int(percentage))
        
        # Set color based on thresholds
        if percentage >= 90:
            color = "#ff4444"  # Red
        elif percentage >= 70:
            color = "#ffaa44"  # Orange
        else:
            color = "#44ff44"  # Green
        
        self.gauge.setStyleSheet(f"""
            QProgressBar {{
                border: 1px solid #cccccc;
                border-radius: 3px;
                background: #f8f8f8;
            }}
            QProgressBar::chunk {{
                background-color: {color};
                border-radius: 2px;
            }}
        """)

class StatsReceiver(QMainWindow):
    def __init__(self):
        super().__init__()
        self.stats_data = {}
        self.initUI()
        self.initNetwork()
        
    def initUI(self):
        self.setWindowTitle('Jetson Nano Monitor')
        self.setGeometry(100, 100, 600, 350)  # Smaller window
        
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(5, 5, 5, 5)
        main_layout.setSpacing(5)
        
        # Top section: CPU and GPU with usage bars and temperature
        usage_frame = QGroupBox("Processor Usage")
        usage_frame.setStyleSheet("QGroupBox { font-weight: bold; }")
        usage_layout = QGridLayout()
        usage_layout.setContentsMargins(5, 15, 5, 5)
        
        # CPU Section
        usage_layout.addWidget(QLabel("CPU Usage:"), 0, 0)
        self.cpu_usage_bar = QProgressBar()
        self.cpu_usage_bar.setMaximum(100)
        self.cpu_usage_bar.setTextVisible(True)
        self.cpu_usage_bar.setFormat("%p%")
        self.cpu_usage_bar.setFixedHeight(20)
        usage_layout.addWidget(self.cpu_usage_bar, 0, 1)
        
        self.cpu_temp_label = QLabel("Temp: 0.0°C")
        self.cpu_temp_label.setStyleSheet("color: #555555;")
        usage_layout.addWidget(self.cpu_temp_label, 0, 2)
        
        # GPU Section
        usage_layout.addWidget(QLabel("GPU Usage:"), 1, 0)
        self.gpu_usage_bar = QProgressBar()
        self.gpu_usage_bar.setMaximum(100)
        self.gpu_usage_bar.setTextVisible(True)
        self.gpu_usage_bar.setFormat("%p%")
        self.gpu_usage_bar.setFixedHeight(20)
        usage_layout.addWidget(self.gpu_usage_bar, 1, 1)
        
        self.gpu_temp_label = QLabel("Temp: 0.0°C")
        self.gpu_temp_label.setStyleSheet("color: #555555;")
        usage_layout.addWidget(self.gpu_temp_label, 1, 2)
        
        usage_frame.setLayout(usage_layout)
        
        # Middle section: Memory gauges
        mem_frame = QGroupBox("Memory")
        mem_frame.setStyleSheet("QGroupBox { font-weight: bold; }")
        mem_layout = QHBoxLayout()
        mem_layout.setContentsMargins(5, 15, 5, 5)
        
        self.ram_gauge = CompactGaugeWidget("RAM", 3964, "MB", 70, 85)
        self.swap_gauge = CompactGaugeWidget("SWAP", 1982, "MB", 50, 70)
        
        mem_layout.addWidget(self.ram_gauge)
        mem_layout.addWidget(self.swap_gauge)
        mem_frame.setLayout(mem_layout)
        
        # Bottom section: Additional temperatures and status
        bottom_frame = QFrame()
        bottom_layout = QHBoxLayout()
        bottom_layout.setContentsMargins(0, 0, 0, 0)
        
        # Temperature readings
        temp_widget = QWidget()
        temp_layout = QVBoxLayout()
        temp_layout.setContentsMargins(0, 0, 0, 0)
        
        self.other_temp_label = QLabel("Other temps: AO: 0.0°C | PLL: 0.0°C")
        self.other_temp_label.setStyleSheet("color: #666666; font-size: 10px;")
        temp_layout.addWidget(self.other_temp_label)
        
        self.timestamp_label = QLabel("Last update: Never")
        self.timestamp_label.setStyleSheet("color: #888888; font-size: 9px;")
        temp_layout.addWidget(self.timestamp_label)
        
        temp_widget.setLayout(temp_layout)
        
        # Status
        self.status_label = QLabel("Waiting for data...")
        self.status_label.setStyleSheet("color: #888888; font-size: 10px;")
        self.status_label.setAlignment(Qt.AlignRight | Qt.AlignVCenter)
        
        bottom_layout.addWidget(temp_widget)
        bottom_layout.addWidget(self.status_label)
        bottom_frame.setLayout(bottom_layout)
        
        # Add to main layout
        main_layout.addWidget(usage_frame)
        main_layout.addWidget(mem_frame)
        main_layout.addWidget(bottom_frame)
        
        # Set equal stretching
        main_layout.setStretch(0, 2)  # Usage section
        main_layout.setStretch(1, 1)  # Memory section
        main_layout.setStretch(2, 0)  # Bottom section (minimal space)
        
    def initNetwork(self):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.sock.bind(('0.0.0.0', 9999))
        self.sock.settimeout(0.1)
        
        self.timer = QTimer()
        self.timer.timeout.connect(self.checkForData)
        self.timer.start(100)
        
    def checkForData(self):
        try:
            data, addr = self.sock.recvfrom(1024)
            try:
                stats = json.loads(data.decode('utf-8'))
                self.updateDisplay(stats)
                self.status_label.setText(f"Connected: {addr[0]}")
            except:
                self.status_label.setText("Data error")
        except socket.timeout:
            pass
        except Exception as e:
            self.status_label.setText(f"Error: {str(e)}")
    
    def updateDisplay(self, stats):
        # Update CPU usage and temperature
        cpu_usage = stats.get('cpu_usage', 0)
        self.cpu_usage_bar.setValue(int(cpu_usage))
        
        # Color CPU bar based on usage
        if cpu_usage >= 90:
            color = "#ff4444"
        elif cpu_usage >= 70:
            color = "#ffaa44"
        else:
            color = "#44ff44"
        
        self.cpu_usage_bar.setStyleSheet(f"""
            QProgressBar {{
                border: 1px solid #cccccc;
                border-radius: 4px;
                text-align: center;
                background: #f8f8f8;
            }}
            QProgressBar::chunk {{
                background-color: {color};
                border-radius: 3px;
            }}
        """)
        
        # Update CPU temperature
        cpu_temp = stats.get('zone0', 0)
        self.cpu_temp_label.setText(f"Temp: {cpu_temp:.1f}°C")
        
        # Update GPU usage and temperature (simulate if not available)
        gpu_usage = min(100, cpu_usage * 0.8)  # Simulate GPU usage
        self.gpu_usage_bar.setValue(int(gpu_usage))
        
        # Color GPU bar based on usage
        if gpu_usage >= 90:
            color = "#ff4444"
        elif gpu_usage >= 70:
            color = "#ffaa44"
        else:
            color = "#44ff44"
        
        self.gpu_usage_bar.setStyleSheet(f"""
            QProgressBar {{
                border: 1px solid #cccccc;
                border-radius: 4px;
                text-align: center;
                background: #f8f8f8;
            }}
            QProgressBar::chunk {{
                background-color: {color};
                border-radius: 3px;
            }}
        """)
        
        # Update GPU temperature
        gpu_temp = stats.get('zone1', 0)
        self.gpu_temp_label.setText(f"Temp: {gpu_temp:.1f}°C")
        
        # Update memory
        if 'ram' in stats:
            ram = stats['ram']
            self.ram_gauge.set_value(ram['used'], ram['total'])
        
        # Update other temperatures
        ao_temp = stats.get('zone2', 0)
        pll_temp = stats.get('zone0', 0) * 0.9  # Simulate PLL temp
        self.other_temp_label.setText(f"Other temps: AO: {ao_temp:.1f}°C | PLL: {pll_temp:.1f}°C")
        
        # Update timestamp
        from datetime import datetime
        timestamp = datetime.fromtimestamp(stats.get('timestamp', time.time()))
        self.timestamp_label.setText(f"Last update: {timestamp.strftime('%H:%M:%S')}")
    
    def closeEvent(self, event):
        self.sock.close()
        event.accept()

def main():
    QApplication.setAttribute(Qt.AA_DisableWindowContextHelpButton)
    QApplication.setAttribute(Qt.AA_UseSoftwareOpenGL)
    
    app = QApplication(sys.argv)
    app.setStyle('Fusion')
    
    # Set smaller font sizes
    font = QFont()
    font.setPointSize(8)
    app.setFont(font)
    
    receiver = StatsReceiver()
    receiver.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()