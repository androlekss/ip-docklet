using Plank;

namespace MyIP {

public class IpPreferences : DockItemPreferences
{

    public MyIP.IpPreferences.with_file(GLib.File file) {
        base.with_file(file);
    }

    protected override void reset_properties()
    {
        /*APIKey = "";
           Username = "";
           MaxEntries = 10;
           RoundedCorners = false;*/
    }
}
}
