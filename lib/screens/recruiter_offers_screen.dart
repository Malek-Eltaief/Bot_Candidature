import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecruiterOffersScreen extends StatefulWidget {
  const RecruiterOffersScreen({super.key});

  @override
  State<RecruiterOffersScreen> createState() => _RecruiterOffersScreenState();
}

class _RecruiterOffersScreenState extends State<RecruiterOffersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _recruiterId;

  @override
  void initState() {
    super.initState();
    _recruiterId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_recruiterId.isEmpty) {
      debugPrint('No authenticated user found. RecruiterId is empty.');
    } else {
      debugPrint('RecruiterId: $_recruiterId');
      // Test manuel de la connexion Firestore
      FirebaseFirestore.instance
          .collection('jobs')
          .where('createdBy', isEqualTo: _recruiterId)
          .get()
          .then((snapshot) {
        debugPrint('Manual check: ${snapshot.docs.length} jobs found');
      }).catchError((error) {
        debugPrint('Manual check error: $error');
      });
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associated Offers'),
        backgroundColor: Colors.blue[700],
        elevation: 4.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           
            StreamBuilder<QuerySnapshot>(
              stream: _recruiterId.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('jobs')
                      .where('createdBy', isEqualTo: _recruiterId)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Stream error: ${snapshot.error}');
                  return Center(
                    child: Text('Error loading jobs: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  debugPrint('No data or empty snapshot. Docs count: ${snapshot.data?.docs.length ?? 0} for recruiterId: $_recruiterId');
                  return const Center(child: Text('No jobs available'));
                }

                final allJobs = snapshot.data!.docs;
                debugPrint('Total jobs retrieved: ${allJobs.length}');
                final jobs = _searchQuery.isNotEmpty
                    ? allJobs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final title = data['title']?.toString().toLowerCase() ?? '';
                        final company = data['company']?.toString().toLowerCase() ?? '';
                        return title.contains(_searchQuery.toLowerCase()) ||
                            company.contains(_searchQuery.toLowerCase());
                      }).toList()
                    : allJobs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    final jobData = job.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 10.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15.0),
                        title: Text(
                          jobData['title'] ?? 'No title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(jobData['company'] ?? 'Unknown company'),
                            Text(jobData['location'] ?? 'Unknown location'),
                            Text(jobData['contractType'] ?? 'Unknown type'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}