import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show forgetMissingCovers;

import 'app_shell.dart';
import 'app_version.dart';
import 'providers.dart';
import 'routes.dart';
import 'snack_bars.dart';

/// More: what a listener reaches now and then rather than every day (§2.6).
///
/// The tab the design asks for, and it earns its place now that it holds more than Settings. What
/// is deliberately *not* here is History and Downloads: both used to hide behind the library's app
/// bar, both are things a listener goes to directly and often, and both now have tabs of their own.
///
/// Everything here opens a screen that already existed. This is a signpost, and it is worth having
/// as one: before it, Settings was a menu item inside another screen's overflow, which is where
/// things go to be lost.
class MoreScreen extends ConsumerStatefulWidget {
  const MoreScreen({super.key});

  @override
  ConsumerState<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends ConsumerState<MoreScreen> {
  var _lookingForCovers = false;

  /// Reads every coverless book's files again, having first forgotten that they were looked at.
  ///
  /// A book with no cover is recorded as such so that every start does not read every file again.
  /// That makes the answer permanent, and it should not be: artwork gets added beside files, and
  /// the readers get better at finding it. This is how a listener asks again.
  Future<void> _lookForCovers() async {
    if (_lookingForCovers) return;
    setState(() => _lookingForCovers = true);
    final services = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final asked = await forgetMissingCovers(services.database);
      if (asked == 0) {
        tellInSnackBar(messenger, 'Every book already has a cover');
        return;
      }
      await services.lookForMissingCovers(
        onError: (error, _) => tellInSnackBar(messenger, '$error'),
      );
      tellInSnackBar(
        messenger,
        asked == 1 ? 'Looked at 1 book again' : 'Looked at $asked books again',
      );
    } catch (error) {
      tellInSnackBar(messenger, 'Could not look for covers: $error');
    } finally {
      if (mounted) setState(() => _lookingForCovers = false);
    }
  }

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
          ListTile(
            leading: _lookingForCovers
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_search_outlined),
            title: const Text('Look for missing covers'),
            subtitle: const Text(
              'Reads the files of books with no cover again',
            ),
            enabled: !_lookingForCovers,
            onTap: _lookForCovers,
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
