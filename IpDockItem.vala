using Plank;
using Cairo;
using Gee;

namespace MyIP {

private bool vpn_is_active = false;

public class IpDockItem : DockletItem
{
    private const uint FETCH_INTERVAL_SECONDS = 60;

    private GLib.Mutex ip_mutex;
    private string current_ip = "Fetching IP...";
    private Gtk.Clipboard clipboard;
    private Gdk.Pixbuf icon_pixbuf;
    private IpPreferences prefs;
    private WireGuardManager wg_manager;
    private SettingsManager settings;


    private uint fetch_timer_id = 0;

    public IpDockItem.with_dockitem_file(GLib.File file) {
        GLib.Object(Prefs: new IpPreferences.with_file(file));
    }

    construct {

        prefs = (IpPreferences) Prefs;
        wg_manager = new WireGuardManager("wg0");
        settings = new SettingsManager();

        Icon = "resource://" + MyIP.G_RESOURCE_PATH + "/icons/ip.png";

        clipboard = Gtk.Clipboard.get(Gdk.Atom.intern("CLIPBOARD", true));

        try {
            icon_pixbuf = new Gdk.Pixbuf.from_resource(MyIP.G_RESOURCE_PATH + "/icons/ip.png");
        }
        catch(Error e) {
            warning("Error: " + e.message);
        }

        start_auto_refresh();
        update_ip.begin();
    }

    ~IpDockItem()
    {
        if(fetch_timer_id != 0)
        {
            GLib.Source.remove(fetch_timer_id);
            fetch_timer_id = 0;
        }
    }

    private async void update_ip()
    {
        try {

            var session = new Soup.Session();
            var message = new Soup.Message("GET", "http://ip-api.com/json/");

            var stream = yield session.send_async(message, GLib.Priority.DEFAULT, null);
            var bytes = yield stream.read_bytes_async(4096, GLib.Priority.DEFAULT, null);
            var data = bytes.get_data();

            string json_text = "";
            if(data != null)
            {
                json_text = (string) (data[0 : data.length]);
            }

            int end = json_text.index_of_char('}') + 1;
            json_text = json_text.substring(0, end);

            var parser = new Json.Parser();
            parser.load_from_data((string) json_text, -1);
            var root = parser.get_root().get_object();

            var ip_text = root.get_string_member("query");
            var country_code = root.get_string_member("countryCode"); // e.g. "UA"

            ip_mutex.lock ();
            current_ip = ip_text;
            ip_mutex.unlock();

            var emoji_flag = country_to_flag(country_code);
            Text = "%s IP: %s".printf(emoji_flag, ip_text);

            vpn_is_active = wg_manager.is_active();
            update_icon();

        }
        catch(Error e) {

            ip_mutex.lock ();
            current_ip = "Error: " + e.message;
            ip_mutex.unlock();
            Text = current_ip;
        }
    }


    private string country_to_flag(string code)
    {
        var flag = "";

        for(int i = 0; i < code.length; i++)
        {
            char c = code[i];
            char upper = (c >= 'a' && c <= 'z') ? (char)(c - 32) : c;

            int offset = (int) upper - (int) 'A';
            unichar u = 0x1F1E6 + offset;

            flag += u.to_string();
        }

        return flag;
    }

    protected override AnimationType on_hovered()
    {
        update_ip.begin();
        return AnimationType.NONE;
    }

    protected override AnimationType on_clicked(PopupButton button, Gdk.ModifierType mod, uint32 event_time)
    {
        if((button & PopupButton.LEFT) != 0)
        {
            if(current_ip.length > 0)
            {
                clipboard.set_text(current_ip, (int) current_ip.length);
            }
        }

        return AnimationType.NONE;
    }

    public override ArrayList<Gtk.MenuItem> get_menu_items()
    {
        var items = new ArrayList<Gtk.MenuItem>();

        var refresh_item = new Gtk.MenuItem.with_label(_("Refresh IP"));
        refresh_item.activate.connect(() => {
                update_ip.begin();
            });
        items.add(refresh_item);

        var separator = new Gtk.SeparatorMenuItem();
        items.add(separator);

        var copy_item = new Gtk.MenuItem.with_label(_("Copy IP to Clipboard"));
        copy_item.activate.connect(() => {
                if(current_ip.length > 0)
                {
                    clipboard.set_text(current_ip, (int) current_ip.length);
                }
            });

        items.add(copy_item);

        var toggle_vpn_item = new Gtk.MenuItem.with_label(_("Toggle WireGuard VPN"));
        //toggle_vpn_item.sensitive = wg_manager.is_available();
        toggle_vpn_item.activate.connect(() => {
                wg_manager.toggle();
                GLib.Timeout.add(1000, () => {
                    if(is_network_ready())
                    {
                        update_ip.begin();
                    }
                    else
                    {
                        stderr.printf("Network not ready after toggle\n");
                    }
                    return false;
                });
                update_ip.begin();
            });
        items.add(toggle_vpn_item);

        var auto_refresh_item = new Gtk.CheckMenuItem.with_label(_("Auto Refresh"));
        auto_refresh_item.set_active(settings.auto_refresh_enabled);
        auto_refresh_item.toggled.connect(() => {
                settings.auto_refresh_enabled = auto_refresh_item.get_active();
                settings.save();
                start_auto_refresh();
            });
        items.add(auto_refresh_item);

        var delay_menu = new Gtk.Menu();
        int[] delays = {
            15, 30, 60, 120
        };

        foreach(int d in delays)
        {
            int delay_value = d;
            var item = new Gtk.CheckMenuItem.with_label(
                _("Refresh every %d seconds").printf(delay_value)
                );
            if(settings.auto_refresh_delay_seconds == delay_value)
            {
                item.set_active(true);
            }
            item.activate.connect(() => {
                    settings.auto_refresh_delay_seconds = delay_value;
                    settings.save();
                    start_auto_refresh();
                });
            delay_menu.append(item);
        }

        var delay_root = new Gtk.MenuItem.with_label(_("Set Refresh Delay"));
        delay_menu.show_all();
        delay_root.set_submenu(delay_menu);
        items.add(delay_root);

        return items;
    }

    private void start_auto_refresh()
    {
        if(fetch_timer_id > 0)
            GLib.Source.remove(fetch_timer_id);

        if(settings.auto_refresh_enabled)
        {
            fetch_timer_id = GLib.Timeout.add_seconds(settings.auto_refresh_delay_seconds, () => {
                    update_ip.begin();
                    return true;
                });
        }
    }


    private bool is_network_ready()
    {
        try {
            string[] cmd = {
                "/bin/sh", "-c", "ping -c 1 ip-api.com"
            };
            int exit_code;
            Process.spawn_sync(null, cmd, null, SpawnFlags.SEARCH_PATH, null, null, null, out exit_code);
            return exit_code == 0;
        }
        catch(Error e) {
            return false;
        }
    }

    private void update_icon()
    {
        var icon_name = vpn_is_active ? "wireguard-active.png" : "wireguard-inactive.png";
        Icon = "resource://at/greyh/myip/icons/" + icon_name;
    }
}
}
