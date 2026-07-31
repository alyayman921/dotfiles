import re
import sublime
import sublime_plugin
import os


class SaveOpenTabsCommand(sublime_plugin.WindowCommand):
    """
    Saves the file paths of all open tabs in the current window to a
    plain text file (one path per line, no decoration) — the exact
    format the "Open Files In List" package expects, so you can later
    select that file's contents and run `open_files_in_list` to
    reopen everything.

    Output location, in order of preference:
      1. The first folder in the current Sublime project
      2. The directory of the currently active file
      3. The process's current working directory

    Output filename is "setN.txt", where N is one higher than the
    highest existing setN.txt already in that directory (starting at
    1 if none exist). The file is written but not opened.
    """

    def run(self):
        window = self.window

        paths = []
        skipped = 0
        for view in window.views():
            file_name = view.file_name()
            if file_name:
                paths.append(file_name)
            else:
                skipped += 1

        if not paths:
            sublime.status_message("Save Open Tabs: no saved tabs to write out.")
            return

        target_dir = self.get_work_dir(window)
        filename = self.get_next_filename(target_dir)
        output_path = os.path.join(target_dir, filename)

        try:
            with open(output_path, "w", encoding="utf-8") as f:
                f.write("\n".join(paths))
        except OSError as e:
            sublime.error_message("Save Open Tabs: could not write list:\n%s" % e)
            return

        msg = "Saved %d open tab(s) to %s" % (len(paths), output_path)
        if skipped:
            msg += " (%d unsaved tab(s) skipped)" % skipped
        sublime.status_message(msg)
        print(msg)

    def get_next_filename(self, target_dir):
        pattern = re.compile(r"^set(\d+)\.txt$")
        highest = 0
        try:
            for name in os.listdir(target_dir):
                match = pattern.match(name)
                if match:
                    highest = max(highest, int(match.group(1)))
        except OSError:
            pass
        return "set%d.txt" % (highest + 1)

    def get_work_dir(self, window):
        folders = window.folders()
        if folders:
            return folders[0]

        active_view = window.active_view()
        if active_view and active_view.file_name():
            return os.path.dirname(active_view.file_name())

        return os.getcwd()