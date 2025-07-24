import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({super.key});

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _localeReady = false;

  // Simulação de disciplinas agendadas
  final List<_CalendarEvent> _events = [
    _CalendarEvent(
      date: DateTime(2025, 7, 17),
      subject: 'Programação Linear',
      time: '08:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 17),
      subject: 'Matemática',
      time: '10:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 18),
      subject: 'Química',
      time: '09:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 18),
      subject: 'História',
      time: '14:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 19),
      subject: 'Física',
      time: '11:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 22),
      subject: 'Matemática',
      time: '08:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 22),
      subject: 'Química',
      time: '13:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 25),
      subject: 'História',
      time: '09:00',
    ),
    _CalendarEvent(
      date: DateTime(2025, 7, 30),
      subject: 'Física',
      time: '15:00',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('pt_BR', null).then((_) {
      setState(() {
        _localeReady = true;
      });
    });
  }

  List<_CalendarEvent> get _eventsForSelectedDay {
    return _events.where((e) {
      return e.date.year == _selectedDay!.year &&
          e.date.month == _selectedDay!.month &&
          e.date.day == _selectedDay!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final monthYear =
        DateFormat('MMMM yyyy', 'pt_BR').format(_focusedDay).toUpperCase();
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Calendário',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month - 1,
                          1,
                        );
                        _selectedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month,
                          1,
                        );
                      });
                    },
                  ),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month + 1,
                          1,
                        );
                        _selectedDay = DateTime(
                          _focusedDay.year,
                          _focusedDay.month,
                          1,
                        );
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _CalendarWidget(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay!,
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay = DateTime(day.year, day.month, day.day);
                    _focusedDay = DateTime(day.year, day.month, day.day);
                  });
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child:
                    _eventsForSelectedDay.isNotEmpty
                        ? ListView.builder(
                          itemCount: _eventsForSelectedDay.length,
                          itemBuilder:
                              (context, i) =>
                                  _EventCard(event: _eventsForSelectedDay[i]),
                        )
                        : const Center(
                          child: Text(
                            'Nenhum evento para este dia.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final DateTime date;
  final String subject;
  final String time;
  _CalendarEvent({
    required this.date,
    required this.subject,
    required this.time,
  });
}

class _EventCard extends StatelessWidget {
  final _CalendarEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF2953A5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.time,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const _CalendarWidget({
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final lastDayOfMonth = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weekDayOffset = firstDayOfMonth.weekday % 7;
    final days = List.generate(daysInMonth, (i) => i + 1);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in [
              'DOM',
              'SEG',
              'TER',
              'QUA',
              'QUI',
              'SEX',
              'SÁB',
            ])
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 0,
            childAspectRatio: 1.2,
          ),
          itemCount: daysInMonth + weekDayOffset,
          itemBuilder: (context, i) {
            if (i < weekDayOffset) {
              return const SizedBox();
            }
            final day = days[i - weekDayOffset];
            final date = DateTime(focusedDay.year, focusedDay.month, day);
            final isSelected =
                date.year == selectedDay.year &&
                date.month == selectedDay.month &&
                date.day == selectedDay.day;
            return GestureDetector(
              onTap: () => onDaySelected(date),
              child: Container(
                width: 36,
                height: 36,
                decoration:
                    isSelected
                        ? const BoxDecoration(
                          color: Color(0xFF2953A5),
                          shape: BoxShape.circle,
                        )
                        : null,
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
