import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedTag = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  // Tags must tally with what you save in Create Event
  final List<String> _tags = ['All', 'Academic', 'Tech', 'Food', 'Fun', 'Sports', 'Workshop'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tags.length,
              itemBuilder: (context, index) {
                final tag = _tags[index];
                final isSelected = _selectedTag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _selectedTag = tag),
                    backgroundColor: Colors.white,
                    selectedColor: Colors.purple[100],
                    checkmarkColor: Colors.purple,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('events')
            .stream(primaryKey: ['id'])
            .order('start_datetime'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final events = snapshot.data!.where((e) {
            final title = (e['title'] as String).toLowerCase();
            final search = _searchCtrl.text.toLowerCase();
            final tags = List<String>.from(e['tags'] ?? []);
            
            final matchesSearch = title.contains(search);
            final matchesTag = _selectedTag == 'All' || tags.contains(_selectedTag);
            
            return matchesSearch && matchesTag;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState((){}),
                  decoration: InputDecoration(
                    hintText: "Search events...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_,__) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final date = DateTime.parse(event['start_datetime']);
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: Image.network(
                                event['image_url'] ?? 'https://via.placeholder.com/300', 
                                height: 180, 
                                width: double.infinity, 
                                fit: BoxFit.cover
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: (event['tags'] as List).take(3).map<Widget>((t) => 
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text("#$t", style: TextStyle(color: Colors.purple[700], fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    ).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(event['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(DateFormat('dd MMM, hh:mm a').format(date), style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 8),
                                      Text(event['location'] ?? 'TBA', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen())),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}