import 'package:flutter/material.dart';

class RatingScreen extends StatefulWidget {
  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitRating() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Thank you!"),
        content: Text("Your feedback has been submitted."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.popUntil(context, ModalRoute.withName('/'));
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _rating = index;
        });
      },
      child: Icon(
        Icons.star,
        size: 36,
        color: index <= _rating ? Colors.orange : Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Rate Your Provider"),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage:
                  NetworkImage("https://via.placeholder.com/150"),
            ),
            SizedBox(height: 12),
            Text(
              "Anna's Cleaners",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              "House Cleaning",
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            Text(
              "How was the service?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Leave a comment (optional)",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _rating == 0 ? null : _submitRating,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _rating == 0 ? Colors.grey : Color(0xFF4B2EFF),
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Submit Rating",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
