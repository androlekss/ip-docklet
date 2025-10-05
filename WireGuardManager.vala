namespace MyIP {
public class WireGuardManager : Object
{
    private string interface_name;

    public WireGuardManager(string interface_name = "wg0")
    {
        this.interface_name = interface_name;
    }

    public bool is_available()
    {
        try {
            string[] cmd = {
                "/bin/sh", "-c", "ip link show " + interface_name
            };
            string stdout;
            int exit_code;
            Process.spawn_sync(null, cmd, null, SpawnFlags.SEARCH_PATH, null, out stdout, null, out exit_code);
            return exit_code == 0;
        }
        catch(Error e) {
            return false;
        }
    }

    public bool is_active()
    {
        try {

            string[] check_cmd = {
                "/bin/sh", "-c", "ip link show wg0"
            };
            string stdout;
            int exit_code;

            Process.spawn_sync(null, check_cmd, null, SpawnFlags.SEARCH_PATH, null, out stdout, null, out exit_code);

            return exit_code == 0;
        }
        catch(Error e) {
            return false;
        }
    }

    public void toggle()
    {
        try
        {
            if(is_active())
            {
                Process.spawn_command_line_async("sudo /usr/bin/wg-quick down " + interface_name);
            }
            else
            {
                Process.spawn_command_line_async("sudo /usr/bin/wg-quick up " + interface_name);
            }
        }
        catch(Error e) {
            stderr.printf("WireGuard toggle failed: %s\n", e.message);
        }
    }

    public string get_status_icon()
    {
        return is_active() ? "wireguard-active.png" : "wireguard-inactive.png";
    }
}
}
