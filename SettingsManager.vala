public class SettingsManager : Object {

  private string config_path;
  public bool auto_refresh_enabled { get; set; default = true; }
  public int auto_refresh_delay_seconds { get; set; default = 30; }

  public SettingsManager(string app_name = "myip-docklet") {
    config_path = GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), app_name + ".ini");
    load();
  }

  public void load() {
    if (!GLib.FileUtils.test(config_path, GLib.FileTest.EXISTS))
      return;

    try {
      var keyfile = new GLib.KeyFile();
      keyfile.load_from_file(config_path, GLib.KeyFileFlags.NONE);

      auto_refresh_enabled = keyfile.get_boolean("Refresh", "Enabled");
      auto_refresh_delay_seconds = keyfile.get_integer("Refresh", "Delay");
    } catch (Error e) {
      stderr.printf("Settings load failed: %s\n", e.message);
    }
  }

  public void save() {
    try {
      var keyfile = new GLib.KeyFile();
      keyfile.set_boolean("Refresh", "Enabled", auto_refresh_enabled);
      keyfile.set_integer("Refresh", "Delay", auto_refresh_delay_seconds);

      string contents = keyfile.to_data();
      GLib.FileUtils.set_contents(config_path, contents);
    } catch (Error e) {
      stderr.printf("Settings save failed: %s\n", e.message);
    }
  }
}

