import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Define State
class MarketplaceState {
  final List<Map<String, dynamic>> allItems;      // Raw data from DB
  final List<Map<String, dynamic>> displayedItems; // Data shown after filter/search
  final String selectedFilter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  MarketplaceState({
    this.allItems = const [],
    this.displayedItems = const [],
    this.selectedFilter = 'All',
    this.searchQuery = '',
    this.isLoading = true,
    this.errorMessage,
  });

  MarketplaceState copyWith({
    List<Map<String, dynamic>>? allItems,
    List<Map<String, dynamic>>? displayedItems,
    String? selectedFilter,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MarketplaceState(
      allItems: allItems ?? this.allItems,
      displayedItems: displayedItems ?? this.displayedItems,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// 2. Define Cubit (Logic)
class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit() : super(MarketplaceState()) {
    _subscribeToRealtime();
  }

  StreamSubscription? _subscription;
  final _supabase = Supabase.instance.client;

  // Replaces StreamBuilder logic
  void _subscribeToRealtime() {
    emit(state.copyWith(isLoading: true));

    _subscription = _supabase
        .from('listings')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
          // Convert raw data
          final items = List<Map<String, dynamic>>.from(data);
          
          // Apply current filters immediately to new data
          final filtered = _applyFilters(items, state.selectedFilter, state.searchQuery);

          emit(state.copyWith(
            allItems: items,
            displayedItems: filtered,
            isLoading: false,
          ));
        }, onError: (error) {
          emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
        });
  }

  // Update Filter (Chips)
  void updateFilter(String filter) {
    final filtered = _applyFilters(state.allItems, filter, state.searchQuery);
    emit(state.copyWith(selectedFilter: filter, displayedItems: filtered));
  }

  // Update Search (TextField)
  void updateSearch(String query) {
    final filtered = _applyFilters(state.allItems, state.selectedFilter, query);
    emit(state.copyWith(searchQuery: query, displayedItems: filtered));
  }

  // The Helper Logic (Extracted from your original build method)
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> items, String filter, String query) {
    return items.where((i) {
      final matchesCategory = filter == 'All' || i['category'] == filter;
      final matchesSearch = query.isEmpty ||
          (i['title'] as String).toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}