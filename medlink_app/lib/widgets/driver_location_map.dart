import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';
import '../utils/theme.dart';

class DriverLocationMap extends StatefulWidget {
  const DriverLocationMap({super.key, required this.driverId});
  final String driverId;

  @override
  State<DriverLocationMap> createState() => _DriverLocationMapState();
}

class _DriverLocationMapState extends State<DriverLocationMap> {
  LatLng? _location;
  RealtimeChannel? _channel;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final service = context.read<ChatService>();
    final row = await service.fetchDriverLocation(widget.driverId);
    if (row != null) _update(row);
    _channel = service.subscribeToDriverLocation(widget.driverId, _update);
  }

  void _update(Map<String, dynamic> row) {
    final next = LatLng(
      (row['latitude'] as num).toDouble(),
      (row['longitude'] as num).toDouble(),
    );
    if (!mounted) return;
    setState(() => _location = next);
    _map?.animateCamera(CameraUpdate.newLatLng(next));
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.driverLocationTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 220,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: _location == null
                ? Center(
                    child: Text(
                      l10n.driverLocationUnavailable,
                      textAlign: TextAlign.center,
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _location!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _map = controller,
                    markers: {
                      Marker(
                        markerId: const MarkerId('driver'),
                        position: _location!,
                        infoWindow: InfoWindow(title: l10n.driverLocationTitle),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
          ),
        ),
      ],
    );
  }
}
