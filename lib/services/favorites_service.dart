import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_stations';

  // Get all favorite station IDs
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Add station to favorites
  static Future<bool> addFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    if (!favorites.contains(stationId)) {
      favorites.add(stationId);
      return await prefs.setStringList(_favoritesKey, favorites);
    }
    return true;
  }

  // Remove station from favorites
  static Future<bool> removeFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    
    favorites.remove(stationId);
    return await prefs.setStringList(_favoritesKey, favorites);
  }

  // Check if station is favorite
  static Future<bool> isFavorite(String stationId) async {
    final favorites = await getFavorites();
    return favorites.contains(stationId);
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String stationId) async {
    final isFav = await isFavorite(stationId);
    if (isFav) {
      return await removeFavorite(stationId);
    } else {
      return await addFavorite(stationId);
    }
  }
}
