public static void docklet_init(Plank.DockletManager manager)
{
    manager.register_docklet(typeof (MyIP.IpDocklet));
}

namespace MyIP {
/**
 * Resource path for the icon
 */
public const string G_RESOURCE_PATH = "/at/greyh/myip";

public class IpDocklet : Object, Plank.Docklet
{
    public unowned string get_id()
    {
        return "myip";
    }

    public unowned string get_name()
    {
        return _("myIP");
    }

    public unowned string get_description()
    {
        return _("Displays current public IP");
    }

    public unowned string get_icon()
    {
        return "resource://" + MyIP.G_RESOURCE_PATH + "/icons/ip.png";
    }

    public bool is_supported()
    {
        return true;
    }

    public Plank.DockElement make_element(string launcher, GLib.File file)
    {
        return new IpDockItem.with_dockitem_file(file);
    }
}
}


