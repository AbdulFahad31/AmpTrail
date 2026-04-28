import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:amptrail_mini/constants/colors.dart';
import 'package:amptrail_mini/models/station_model.dart';
import 'package:amptrail_mini/screens/user/profile_screen.dart';
import 'package:amptrail_mini/screens/user/history_screen.dart';
import 'package:amptrail_mini/screens/user/booking_confirmation_screen.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
// To access the token
import 'package:url_launcher/url_launcher.dart';
import 'package:amptrail_mini/services/favorites_service.dart';
import 'package:amptrail_mini/services/station_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:amptrail_mini/config/api_keys.dart';


class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  geo.Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _isNavigating = false;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  int _selectedStationIndex = -1;
  late PageController _pageController;
  Uint8List? _cachedMarkerImage; // Performance Cache
  
  // Search related
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  final StationService _stationService = StationService();
  List<Station> _allStations = [];
  List<Station> _stations = [];
  List<String> _favoriteStationIds = [];
  bool _isLoadingStations = true;
  String? _errorMessage;
  
  // Filter state
  String _filterType = 'all'; // all, available, favorites

  // Nav animation
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    // Defer location init until after the first frame so Scaffold is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeLocation();
    });
    _loadFavorites();
    _fetchStations();
  }

  Future<void> _fetchStations({bool forceRefresh = false}) async {
    setState(() => _isLoadingStations = true);
    try {
      final stations = await _stationService.getStations(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _allStations = stations;
          _isLoadingStations = false;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStations = false;
          _errorMessage = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Network error. Showing cached stations offline.', 
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _navAnimController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FavoritesService.getFavorites();
    if (mounted) {
      setState(() {
        _favoriteStationIds = favorites;
      });
    }
  }

  Future<void> _toggleFavorite(String stationId) async {
    await FavoritesService.toggleFavorite(stationId);
    await _loadFavorites();
  }

  void _onFilterChanged(String filter) {
    if (_filterType == filter) return; // no-op if same filter
    setState(() {
      _filterType = filter;
      _applyFilter();
    });
  }

  void _applyFilter() {
    List<Station> filtered = _allStations;
    if (_filterType == 'available') {
      filtered = _allStations.where((s) => s.isAvailable).toList();
    } else if (_filterType == 'favorites') {
      filtered = _allStations.where((s) => _favoriteStationIds.contains(s.id)).toList();
    }
    // Single setState — caller already wraps us
    _stations = filtered;
    
    // Refresh markers on map
    _addStationMarkers();

    // Reset page controller if list changed
    if (_stations.isNotEmpty && _pageController.hasClients) {
      Future.microtask(() {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
          _onStationSelected(0);
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length > 2) {
        _performPlaceSearch(query);
      } else {
        if (mounted) setState(() => _searchResults = []);
      }
    });
  }

  Future<void> _performPlaceSearch(String query) async {
    final token = MAPBOX_TOKEN;
    final url = "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$token&limit=5&country=IN";

    try {
      setState(() => _isSearching = true);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['features'];
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic feature) {
    final coords = feature['geometry']['coordinates'];
    final name = feature['text'];
    
    _searchController.text = name;
    setState(() {
      _searchResults = [];
    });

    FocusScope.of(context).unfocus();

    double searchLon = coords[0];
    double searchLat = coords[1];

    _allStations.sort((a, b) {
      double distA = _calculateDistance(searchLat, searchLon, a.latitude, a.longitude);
      double distB = _calculateDistance(searchLat, searchLon, b.latitude, b.longitude);
      return distA.compareTo(distB);
    });
    
    _applyFilter();

    if (_stations.isNotEmpty) {
      double closestDist = _calculateDistance(searchLat, searchLon, _stations.first.latitude, _stations.first.longitude);
      if (closestDist > 100) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _mapboxMap?.flyTo(
            CameraOptions(center: Point(coordinates: Position(searchLon, searchLat)), zoom: 11.0),
            MapAnimationOptions(duration: 1500),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No stations found nearby. Showing closest available instead."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(searchLon, searchLat)),
          zoom: 12.0,
        ),
        MapAnimationOptions(duration: 1500),
      );
    }
  }

  Future<void> _initializeLocation() async {
    if (_isLoadingLocation) return;
    
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
    });


    try {
      // Check if location services are enabled
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          _showLocationServiceDialog();
        }
        return;
      }

      // Check and request permission
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          if (mounted) {
            setState(() => _isLoadingLocation = false);
            _showPermissionDeniedDialog();
          }
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingLocation = false);
          _showPermissionDeniedForeverDialog();
        }
        return;
      }

      // Get current position with timeout
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        
        // Show success feedback (get messenger after await, inside mounted check)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Location found!', style: GoogleFonts.outfit()),
              ],
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Fly to location if map is ready
        if (_mapboxMap != null) {
          _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(position.longitude, position.latitude)),
              zoom: 15.0,
            ),
            MapAnimationOptions(duration: 1500, startDelay: 0),
          );
        }
      }
    } on geo.LocationServiceDisabledException {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _showLocationServiceDialog();
      }
    } on geo.PermissionDeniedException {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Text('Could not get location. Try again.', style: GoogleFonts.outfit()),
              ],
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    debugPrint('Mapbox: Map successfully created');
    _mapboxMap = mapboxMap;
    
    // Configure location puck safely
    try {
      _mapboxMap?.location.updateSettings(
         LocationComponentSettings(
           enabled: true,
           pulsingEnabled: true,
         )
      );
    } catch (e) {
      debugPrint('Mapbox: Error setting location component: $e');
    }

    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      debugPrint('Mapbox: Annotation manager created');
      _pointAnnotationManager = manager;
      _addStationMarkers();
    });

    if (_currentPosition != null) {
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
          zoom: 14.0,
        ),
      );
    }
  }

  Future<Uint8List> _createCustomMarker() async {
    if (_cachedMarkerImage != null) return _cachedMarkerImage!;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 64.0;
    const double height = 150.0; // Mid is 75, so tip is at EXACT center
    
    final Paint pinPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    
    // Draw Map Pin Path
    final Path pinPath = Path();
    pinPath.moveTo(32, 75); // Tip of pin exactly in middle of image bounds
    pinPath.quadraticBezierTo(0, 45, 0, 32); // Left edge curve
    pinPath.arcToPoint(
      const Offset(64, 32),
      radius: const Radius.circular(32),
      clockwise: true,
    ); // Top semi-circle
    pinPath.quadraticBezierTo(64, 45, 32, 75); // Right edge curve
    pinPath.close();

    // Soft drop shadow
    canvas.drawShadow(pinPath, Colors.black, 6.0, false);
    
    // Fill pin
    canvas.drawPath(pinPath, pinPaint);

    // Inner White Circle
    final Paint whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(32, 32), 20, whitePaint);

    // EV Station Icon inside the white circle
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.ev_station.codePoint),
      style: TextStyle(
        fontSize: 28.0,
        fontFamily: Icons.ev_station.fontFamily,
        package: Icons.ev_station.fontPackage,
        color: AppColors.primary,
        height: 1.0,
      ),
    );
    textPainter.layout();
    
    final double iconX = 32 - (textPainter.width / 2);
    final double iconY = 32 - (textPainter.height / 2);
    textPainter.paint(canvas, Offset(iconX, iconY));

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    _cachedMarkerImage = byteData!.buffer.asUint8List();
    return _cachedMarkerImage!;
  }

  Future<void> _addStationMarkers() async {
    if (_pointAnnotationManager == null || _stations.isEmpty) return;
    
    try {
      await _pointAnnotationManager?.deleteAll();
      
      final Uint8List markerImage = await _createCustomMarker();
      
      List<PointAnnotationOptions> options = [];
      for (var station in _stations) {
        options.add(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(station.longitude, station.latitude)),
            image: markerImage, 
            textField: station.name,
            textOffset: [0.0, 1.2], // Perfect gap underneath the tip
            textAnchor: TextAnchor.TOP,
            textSize: 12.0,
            textColor: Colors.white.value,
            textHaloColor: AppColors.background.value, // Dark background shadow
  
            textHaloWidth: 1.5,
          ),
        );
      }
      
      await _pointAnnotationManager?.createMulti(options);
      debugPrint("Mapbox: Added ${options.length} markers to map");
    } catch (e) {
      debugPrint("Mapbox: Error adding markers: $e");
    }
  }

  void _onStationSelected(int index) {
    if (index < 0 || index >= _stations.length) return;
    
    setState(() {
      _selectedStationIndex = index;
    });
    
    final station = _stations[index];
    
    _mapboxMap?.flyTo(
      CameraOptions(
         center: Point(coordinates: Position(station.longitude, station.latitude)),
         zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  // ... (rest of the dialog methods same as before)
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: AppColors.error, size: 28),
            const SizedBox(width: 12),
            Text(
              'Location Services Off',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Please enable location services to see nearby charging stations on the map.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await geo.Geolocator.openLocationSettings();
              _initializeLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: Text('Open Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_disabled, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Text(
              'Location Permission',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Location permission is required to find nearby charging stations and calculate distances.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: Text('Allow', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permission Required',
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Location permission is permanently denied. Please enable it in app settings.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await geo.Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: Text('Open Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  void _onItemTapped(int index) {
    if (_isNavigating || _currentIndex == index) return;
    HapticFeedback.selectionClick();
    _navAnimController.forward(from: 0);
    setState(() {
      _currentIndex = index;
    });
  }
  
  void _navigateToBookingConfirmation(Station station) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(station: station),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to booking: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMapScreen(),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4)),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
        top: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.map_rounded, 'Map', _currentIndex == 0, 0),
          _buildNavItem(Icons.history_rounded, 'History', _currentIndex == 1, 1),
          _buildNavItem(Icons.person_outline_rounded, 'Profile', _currentIndex == 2, 2),
        ],
      ),
    );
  }

  Widget _buildMapScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapStyle = isDark ? "mapbox://styles/mapbox/dark-v11" : "mapbox://styles/mapbox/streets-v12";

    return Stack(
      children: [
        // Map — stable key so it never re-creates unnecessarily
        RepaintBoundary(
          child: MapWidget(
            key: const ValueKey('mapbox_map'),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(77.5946, 12.9716)),
              zoom: 12.0,
            ),
            styleUri: isDark
                ? 'mapbox://styles/mapbox/dark-v11'
                : 'mapbox://styles/mapbox/streets-v12',
            textureView: true,
            onMapCreated: _onMapCreated,
          ),
        ),

        // Removed Manual Style Switcher in favor of global theme
        
        // Search Bar (Back at Top)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          child: Column(
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceLight),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.outfit(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Search charging stations...',
                            hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
                            border: InputBorder.none,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Suggestions Overlay
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 8)),
                    ],
                  ),
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length > 3 ? 3 : _searchResults.length,
                      itemBuilder: (context, index) {
                        final feature = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined, color: AppColors.primary),
                          title: Text(feature['place_name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                          onTap: () => _selectSearchResult(feature),
                        );
                      },
                    ),
                  ),
                ),
              
              // Filter Chips
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    GestureDetector(
                      onTap: () => _onFilterChanged('all'),
                      child: _buildFilterChip('All', Icons.apps_rounded, _filterType == 'all'),
                    ),
                    GestureDetector(
                      onTap: () => _onFilterChanged('available'),
                      child: _buildFilterChip('Available', Icons.check_circle_rounded, _filterType == 'available'),
                    ),
                    GestureDetector(
                      onTap: () => _onFilterChanged('favorites'),
                      child: _buildFilterChip('Favorites', Icons.favorite_rounded, _filterType == 'favorites'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Map Actions Column
        Positioned(
          bottom: _stations.isNotEmpty ? 240 : 20, 
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: "refresh_btn",
                backgroundColor: AppColors.surface,
                elevation: 4,
                onPressed: () {
                  _fetchStations(forceRefresh: true);
                },
                child: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                mini: true,
                heroTag: "location_btn",
                backgroundColor: AppColors.surface,
                elevation: 4,
                onPressed: _isLoadingLocation ? null : _initializeLocation,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ],
          ),
        ),
        
        if (_isLoadingStations)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 210,
            child: Shimmer.fromColors(
              baseColor: AppColors.surfaceLight,
              highlightColor: AppColors.surface,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.92),
                itemCount: 2,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          )
        else if (_stations.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _stations.length,
              onPageChanged: _onStationSelected,
              itemBuilder: (context, index) {
                final station = _stations[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.hasContentDimensions) {
                      value = (_pageController.page! - index).abs();
                      value = (1 - (value * 0.08)).clamp(0.92, 1.0);
                    }
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      splashColor: AppColors.primary.withOpacity(0.08),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _onStationSelected(index);
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: _buildStationCard(station),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage != null ? 'Error: $_errorMessage' : 'No stations found',
                      style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage != null 
                        ? 'Ensure your Firebase Rules allow reading or check your connection.'
                        : 'Try changing your filters or search area',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
      ],
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.surfaceLight,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
            : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.background : AppColors.textSecondary, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isActive ? AppColors.background : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStationCard(Station station) {
    String? distanceText;
    if (_currentPosition != null) {
      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        station.latitude,
        station.longitude,
      );
      distanceText = _formatDistance(distance);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildConnectorTag(station.id.hashCode % 2 == 0 ? 'CCS2' : 'Type 2'),
                        const SizedBox(width: 6),
                        _buildConnectorTag('22 kW', isPower: true),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _toggleFavorite(station.id),
                icon: Icon(
                  _favoriteStationIds.contains(station.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _favoriteStationIds.contains(station.id) ? AppColors.error : AppColors.textSecondary,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: station.isAvailable ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  station.isAvailable ? 'Available' : 'Busy',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: station.isAvailable ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text(
                station.rating.toString(),
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary, 
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(
                '12 min', // Estimated time
                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (distanceText != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_rounded, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(
                  distanceText,
                  style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            station.address,
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 11),
                  ),
                  Text(
                    '₹${station.pricePerHr}/hr',
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Directions Button
              IconButton(
                onPressed: () => _openDirections(station),
                icon: const Icon(Icons.directions_rounded, color: AppColors.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              // Book Now Button
              Expanded(
                child: ElevatedButton(
                  onPressed: station.isAvailable ? () => _navigateToBookingConfirmation(station) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Book', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _openDirections(Station station) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open directions')),
        );
      }
    }
  }

  Widget _buildConnectorTag(String text, {bool isPower = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPower ? AppColors.accent.withOpacity(0.1) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPower ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceLight.withOpacity(0.5),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          color: isPower ? AppColors.accent : AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}