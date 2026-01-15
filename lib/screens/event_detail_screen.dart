import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:share_plus/share_plus.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? event; // Optional if passing object
  final String? eventId; // Optional if fetching by ID

  const EventDetailScreen({super.key, this.event, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Map<String, dynamic>? _eventData;
  bool _isLoading = true;
  bool _isJoined = false;
  int _attendeeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    final supabase = Supabase.instance.client;
    try {
      // 1. Get Event Data
      if (widget.event != null) {
        _eventData = widget.event;
      } else if (widget.eventId != null) {
        final data = await supabase.from('events').select().eq('id', widget.eventId!).single();
        _eventData = data;
      }

      // 2. Get Attendee Count
      final countRes = await supabase
          .from('event_attendees')
          .count(CountOption.exact)
          .eq('event_id', _eventData!['id']);
      
      // 3. Check if current user joined
      final user = supabase.auth.currentUser;
      bool joined = false;
      if (user != null) {
        final myJoin = await supabase
            .from('event_attendees')
            .select()
            .eq('event_id', _eventData!['id'])
            .eq('user_id', user.id)
            .maybeSingle();
        joined = myJoin != null;
      }

      if (mounted) {
        setState(() {
          _attendeeCount = countRes ?? 0;
          _isJoined = joined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleJoin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please login to join")));
      return;
    }

    setState(() => _isJoined = !_isJoined); // Optimistic UI update

    try {
      if (_isJoined) {
        await Supabase.instance.client.from('event_attendees').insert({
          'event_id': _eventData!['id'],
          'user_id': user.id
        });
        _attendeeCount++;
      } else {
        await Supabase.instance.client.from('event_attendees').delete().match({
          'event_id': _eventData!['id'],
          'user_id': user.id
        });
        _attendeeCount--;
      }
      setState(() {}); // Refresh count UI
    } catch (e) {
      setState(() => _isJoined = !_isJoined); // Revert on error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _eventData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final primary = const Color(0xFFE02097);
    final start = DateTime.parse(_eventData!['start_datetime']);
    final end = _eventData!['end_datetime'] != null ? DateTime.parse(_eventData!['end_datetime']) : null;
    
    String timeString = DateFormat('d MMM, h:mm a').format(start);
    if (end != null) {
      // If same day, just show time range
      if (start.day == end.day && start.month == end.month) {
         timeString += " - ${DateFormat('h:mm a').format(end)}";
      } else {
         timeString += " - ${DateFormat('d MMM, h:mm a').format(end)}";
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                    backgroundColor: Colors.black,
                    appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
                    body: PhotoView(imageProvider: NetworkImage(_eventData!['image_url'] ?? '')),
                  )));
                },
                child: Image.network(_eventData!['image_url'] ?? '', fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image))),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  Share.share("Check out ${_eventData!['title']} at ${_eventData!['location']} on MYKerawang! \n\n${_eventData!['description']}");
                },
              )
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_eventData!['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Tags (Real from DB array)
                  if (_eventData!['tags'] != null)
                    Wrap(
                      spacing: 8,
                      children: List<String>.from(_eventData!['tags']).map((t) => Chip(
                        label: Text(t), 
                        backgroundColor: primary.withOpacity(0.1),
                        labelStyle: TextStyle(color: primary, fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                      )).toList(),
                    ),
                  
                  const SizedBox(height: 24),

                  _infoRow(Icons.calendar_month, timeString, primary),
                  _infoRow(Icons.location_on, _eventData!['location'] ?? 'UiTM Kerawang', primary),
                  _infoRow(Icons.group, "$_attendeeCount people going", primary),

                  const Divider(height: 40),
                  const Text("About", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_eventData!['description'] ?? 'No description provided.', style: TextStyle(color: Colors.grey[800], height: 1.5)),
                  
                  const SizedBox(height: 24),
                  
                  // Real Organizer Card
                  FutureBuilder(
                    future: Supabase.instance.client.from('profiles').select().eq('id', _eventData!['organizer_id']).single(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final org = snapshot.data as Map;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundImage: NetworkImage(org['avatar_url'] ?? '')),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(org['full_name'] ?? 'Organizer', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(org['role'] == 'club' ? "Club Organization" : "Student Organizer", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ]),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: ElevatedButton(
          onPressed: _toggleJoin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isJoined ? Colors.grey[300] : primary, 
            foregroundColor: _isJoined ? Colors.black : Colors.white
          ),
          child: Text(_isJoined ? "Joined" : "Join Event", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}