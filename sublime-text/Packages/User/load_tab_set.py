import os
import sublime
import sublime_plugin


class LoadTabSetCommand(sublime_plugin.WindowCommand):
    """
    Closes all open tabs, then reopens the files listed in setN.txt
    (as written by "Save Open Tabs to List"), using the same
    directory-resolution rules as that command:

      1. The first folder in the current Sublime project
      2. The directory of the currently active file
      3. The process's current working directory

    Requires the "Open Files In List" package, since this hands off
    to its `open_files_in_list` command to do the actual opening.

    Run as: window.run_command("load_tab_set", {"n": 1})
    """

    def run(self, n):
        self.save_dirty_views(self.window)

        target_dir = self.get_work_dir(self.window)
        list_path = os.path.join(target_dir, "set%d.txt" % n)

        if not os.path.isfile(list_path):
            sublime.status_message("Load Tab Set: %s not found" % list_path)
            return

        try:
            with open(list_path, "r", encoding="utf-8") as f:
                contents = f.read()
        except OSError as e:
            sublime.error_message("Load Tab Set: could not read list:\n%s" % e)
            return

        # Close every currently open tab.
        self.window.run_command("close_all")

        # Load the list's contents into a throwaway (unsaved) view.
        # Open Files In List just reads whatever is in the active
        # sheet, so this avoids waiting on an async file load.
        list_view = self.window.new_file()
        list_view.set_scratch(True)
        list_view.set_name("set%d.txt" % n)
        list_view.run_command("append", {"characters": contents})

        # Hand off to Open Files In List, then discard the scratch view.
        self.window.run_command("open_files_in_list")
        list_view.close()

    def save_dirty_views(self, window):
        # `window.run_command("save_all")` silently skips any view
        # that has never been saved to disk (no file_name()), and
        # gives no confirmation that writes actually completed
        # before the next line runs. Save each dirty, file-backed
        # view directly instead, and flag anything we can't save
        # automatically so it's not lost when close_all runs next.
        unsaved = []
        for view in window.views():
            if not view.is_dirty():
                continue
            if not view.file_name():
                unsaved.append(view.name() or "untitled")
                continue
            view.run_command("save")

        if unsaved:
            sublime.status_message(
                "Load Tab Set: skipped unsaved buffer(s), will prompt on close: %s"
                % ", ".join(unsaved)
            )

    def get_work_dir(self, window):
        folders = window.folders()
        if folders:
            return folders[0]

        active_view = window.active_view()
        if active_view and active_view.file_name():
            return os.path.dirname(active_view.file_name())

        return os.getcwd()