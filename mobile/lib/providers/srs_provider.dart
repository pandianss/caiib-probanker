import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/srs_card.dart';

class SRSProvider with ChangeNotifier {
  List<SRSCard> _dueCards = [];
  bool _isLoading = false;

  List<SRSCard> get dueCards => _dueCards;
  bool get isLoading => _isLoading;

  final String baseUrl = 'http://127.0.0.1:8001/api';

  Future<void> fetchDueCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/srs/due/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _dueCards = data.map((json) => SRSCard.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching due cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> recordReview(String cardId, int quality) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/srs/review/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'card_id': cardId, 'quality': quality}),
      );
      
      if (response.statusCode == 200) {
        // Remove from due list if reviewed successfully
        _dueCards.removeWhere((card) => card.id == cardId);
        notifyListeners();
      }
    } catch (e) {
      print('Error recording review: $e');
    }
  }
}
