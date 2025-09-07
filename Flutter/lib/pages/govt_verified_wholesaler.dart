import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme_colors.dart';

class GovtVerifiedWholesalerPage extends StatefulWidget {
  const GovtVerifiedWholesalerPage({super.key});

  @override
  State<GovtVerifiedWholesalerPage> createState() =>
      _GovtVerifiedWholesalerPageState();
}

class _GovtVerifiedWholesalerPageState
    extends State<GovtVerifiedWholesalerPage> {
  List<List<String>> buyers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBuyers();
  }

  Future<void> fetchBuyers() async {
    try {
      final response = await http
          .get(Uri.parse("https://sih25-farmers.onrender.com/buyers"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          buyers = (data['buyers'] as List)
              .map((e) => List<String>.from(e))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Govt Verified Wholesalers",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : buyers.isEmpty
              ? const Center(
                  child: Text("No wholesalers available right now"),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: buyers.length,
                  itemBuilder: (context, index) {
                    final buyer = buyers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.cardGradient,
                        borderRadius: AppBorderRadius.mediumRadius,
                        boxShadow: AppShadows.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: accentColor,
                          child: Text(
                            buyer[0][0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          buyer[0],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: textPrimaryColor,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              buyer[1],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              buyer[2],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: primaryDarkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
