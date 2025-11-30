import 'package:flutter/material.dart';

class BookingModal extends StatefulWidget {
  final Map<String, dynamic> provider;
  final String serviceCategory;
  final double basePrice;

  const BookingModal({
    Key? key,
    required this.provider,
    required this.serviceCategory,
    required this.basePrice,
  }) : super(key: key);

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  String _scheduleType = 'now';
  TimeOfDay? _selectedTime;
  DateTime? _selectedDate;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '7');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    return widget.basePrice * quantity;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF56D16).withOpacity(0.1),
                ),
                child: const Icon(Icons.location_on, size: 50, color: Color(0xFFF56D16)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You can track your booking in the Dashboard - Bookings Section.',
                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close success dialog
                    Navigator.pop(context); // Close booking modal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B2DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Proceed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitBooking() {
    _showSuccessModal();
  }

  @override
  Widget build(BuildContext context) {
    final providerName = widget.provider['name'] ?? 'Provider';
    final rating = (widget.provider['rating'] ?? 0.0).toDouble();
    final ratingCount = widget.provider['ratingCount'] ?? 0;
    final location = (widget.provider['city'] as String?)?.isNotEmpty == true ? widget.provider['city'] as String : '—';
    final distance = widget.provider['distance'] ?? '';
    final total = _calculateTotal();

    return Stack(
      children: [
        DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              children: [
                // (Close button removed — modal dismisses by tapping outside)
                // Content
                SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Very light cancel hint shown at the top of the sheet
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Click outside to cancel',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  // Provider Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(providerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final fill = i < rating.round();
                            return Icon(Icons.star, size: 16, color: fill ? const Color(0xFFF4B740) : Colors.grey.shade300);
                          }),
                          const SizedBox(width: 8),
                          Text('$ratingCount ratings', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        location.isNotEmpty && distance.isNotEmpty ? '$location, $distance km away' : location,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Quantity Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(text: 'How many kilo of ', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
                            TextSpan(text: widget.serviceCategory, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
                            TextSpan(text: '? (PHP ${widget.basePrice.toStringAsFixed(2)}/kg)*', style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          hintText: '7',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Notes Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes to Provider (Include details)*', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          hintText: 'Enter any special instructions...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Schedule
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _scheduleType = 'now'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _scheduleType == 'now' ? const Color(0xFF4B2DFF) : Colors.grey.shade300,
                                    width: _scheduleType == 'now' ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _scheduleType == 'now' ? const Color(0xFF4B2DFF).withOpacity(0.05) : Colors.transparent,
                                ),
                                child: Text(
                                  'Right Now',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _scheduleType == 'now' ? const Color(0xFF4B2DFF) : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _scheduleType = 'later'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _scheduleType == 'later' ? const Color(0xFF4B2DFF) : Colors.grey.shade300,
                                    width: _scheduleType == 'later' ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _scheduleType == 'later' ? const Color(0xFF4B2DFF).withOpacity(0.05) : Colors.transparent,
                                ),
                                child: Text(
                                  'Set Time and Date',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _scheduleType == 'later' ? const Color(0xFF4B2DFF) : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_scheduleType == 'later') ...[
                        const SizedBox(height: 16),
                        const Text('Time and Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _selectedTime?.format(context) ?? '12:30 PM',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _selectedDate != null ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}' : 'December 10, 2025',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                      Text('PHP ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Payment Methods
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = 'Cash'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(width: 2, color: _paymentMethod == 'Cash' ? const Color(0xFF4B2DFF) : Colors.transparent)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.wallet, size: 24, color: _paymentMethod == 'Cash' ? const Color(0xFF4B2DFF) : Colors.black54),
                                const SizedBox(height: 4),
                                Text('Cash', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _paymentMethod == 'Cash' ? const Color(0xFF4B2DFF) : Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _paymentMethod = 'Promos'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(width: 2, color: _paymentMethod == 'Promos' ? const Color(0xFF4B2DFF) : Colors.transparent)),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.card_giftcard, size: 24, color: _paymentMethod == 'Promos' ? const Color(0xFF4B2DFF) : Colors.black54),
                                const SizedBox(height: 4),
                                Text('Promos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _paymentMethod == 'Promos' ? const Color(0xFF4B2DFF) : Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B2DFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Schedule Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ), // end Column
            ), // end SingleChildScrollView
          ], // end inner Stack children
        ), // end inner Container
      ), // end DraggableScrollableSheet builder
    ), // end DraggableScrollableSheet
    

      ], // end root Stack children
    ); // end root Stack
  }
}
