import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. The State (The Data Snapshot)
class EventsState {
  final List<Map<String, dynamic>> allEvents;       // Raw data
  final List<Map<String, dynamic>> displayedEvents; // Filtered data
  final String selectedTag;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  EventsState({
    this.allEvents = const [],
    this.displayedEvents = const [],
    this.selectedTag = 'All',
    this.searchQuery = '',
    this.isLoading = true,
    this.errorMessage,
  });

  EventsState copyWith({
    List<Map<String, dynamic>>? allEvents,
    List<Map<String, dynamic>>? displayedEvents,
    String? selectedTag,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return EventsState(
      allEvents: allEvents ?? this.allEvents,
      displayedEvents: displayedEvents ?? this.displayedEvents,
      selectedTag: selectedTag ?? this.selectedTag,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// 2. The Cubit (The Logic Engine)
class EventsCubit extends Cubit<EventsState> {
  EventsCubit() : super(EventsState()) {
    _subscribeToRealtime();
  }

  StreamSubscription? _subscription;
  final _supabase = Supabase.instance.client;

  void _subscribeToRealtime() {
    emit(state.copyWith(isLoading: true));

    _subscription = _supabase
        .from('events')
        .stream(primaryKey: ['id'])
        .order('start_datetime')
        .listen((data) {
          final items = List<Map<String, dynamic>>.from(data);
          
          // Apply filters immediately upon receiving new data
          final filtered = _applyFilters(items, state.selectedTag, state.searchQuery);

          emit(state.copyWith(
            allEvents: items,
            displayedEvents: filtered,
            isLoading: false,
          ));
        }, onError: (error) {
          emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
        });
  }

  // Update Tag Filter
  void updateTag(String tag) {
    final filtered = _applyFilters(state.allEvents, tag, state.searchQuery);
    emit(state.copyWith(selectedTag: tag, displayedEvents: filtered));
  }

  // Update Search Query
  void updateSearch(String query) {
    final filtered = _applyFilters(state.allEvents, state.selectedTag, query);
    emit(state.copyWith(searchQuery: query, displayedEvents: filtered));
  }

  // The Filter Logic (Extracted from your original code)
  List<Map<String, dynamic>> _applyFilters(
      List<Map<String, dynamic>> items, String tag, String query) {
    return items.where((e) {
      final title = (e['title'] as String).toLowerCase();
      final search = query.toLowerCase();
      // Safe parsing of tags from DB
      final eventTags = List<String>.from(e['tags'] ?? []);
      
      final matchesSearch = title.contains(search);
      final matchesTag = tag == 'All' || eventTags.contains(tag);
      
      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}