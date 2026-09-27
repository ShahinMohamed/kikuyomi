import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_version.dart';
import 'routes.dart';

/// More: what a listener reaches now and then rather than every day (§2.6).
///
/// The tab the design asks for, and it earns its place now that it holds more than Settings. What
/// is deliberately *not* here is History and Downloads: both used to hide behind the library's app
/// bar, both are things a listener goes to directly and often, and both now have tabs of their own.
///
/// Everything here opens a screen that already existed. This is a signpost, and it is worth having
/// as one: before it, Settings was a menu item inside another screen's overflow, which is where
/// things go to be lost.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tab: AppTab.more,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            subtitle: const Text('Backups, and where your books are kept'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const SettingsRoute().push<void>(context),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Extensions'),
            subtitle: const Text('What is installed, and where it came from'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ExtensionsRoute().push<void>(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Repositories'),
            subtitle: const Text('Where extensions are installed from'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const RepositoriesRoute().push<void>(context),
          ),
          ListTile(
            leading: const Icon(Icons.terminal),
            title: const Text('Extension console'),
            subtitle: const Text('What extensions have logged'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => const ExtensionConsoleRoute().push<void>(context),
          ),
          const Divider(),
          // Not a link. A version number is the first thing anyone is asked for in a bug report, so
          // it belongs somewhere a listener can find without being told where to look.
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Kikuyomi'),
            subtitle: const Text(appVersion),
          ),
        ],
      ),
    );
  }
}
