// lib/features/user/screens/government_schemes_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_extensions.dart';

class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({Key? key}) : super(key: key);

  @override
  State<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  
  final List<String> _categories = [
    'All',
    'Healthcare',
    'Senior Citizens',
    'Women & Children',
    'Disability',
    'Financial Aid',
  ];

  final List<SchemeModel> _schemes = [
    SchemeModel(
      id: '1',
      title: 'Ayushman Bharat - PM-JAY',
      description: 'Health insurance scheme providing coverage up to ₹5 lakh per family per year for secondary and tertiary care hospitalization.',
      benefits: '₹5 lakh health cover per family, cashless treatment, 15 crore families covered',
      eligibility: 'Families identified from SECC database, rural and urban poor families',
      documents: ['Aadhaar Card', 'Ration Card', 'SECC Data', 'Mobile Number'],
      category: 'Healthcare',
      applyLink: 'https://pmjay.gov.in/',
      icon: Icons.health_and_safety,
    ),
    SchemeModel(
      id: '2',
      title: 'Pradhan Mantri Janaushadhi Pariyojana',
      description: 'Scheme to provide quality generic medicines at affordable prices through special Janaushadhi Kendras.',
      benefits: 'Generic medicines at 50-90% lower prices, wide range of drugs available',
      eligibility: 'Open to all citizens',
      documents: ['Doctor Prescription', 'Valid ID Proof'],
      category: 'Healthcare',
      applyLink: 'http://janaushadhi.gov.in/',
      icon: Icons.medication,
    ),
    SchemeModel(
      id: '3',
      title: 'National Health Mission (NHM)',
      description: 'Healthcare scheme focusing on maternal and child health, communicable diseases, and strengthening public health systems.',
      benefits: 'Free maternal healthcare, child immunization, disease control programs',
      eligibility: 'All citizens, special focus on rural areas',
      documents: ['Aadhaar Card', 'Residence Proof'],
      category: 'Healthcare',
      applyLink: 'https://nhm.gov.in/',
      icon: Icons.local_hospital,
    ),
    SchemeModel(
      id: '4',
      title: 'Pradhan Mantri Matru Vandana Yojana',
      description: 'Maternity benefit scheme for pregnant and lactating mothers to compensate for wage loss.',
      benefits: '₹5,000 cash incentive for first living child, ₹6,000 total benefits',
      eligibility: 'Pregnant women of 19+ years, first living child, government/PSU employees excluded',
      documents: ['MCP Card', 'Aadhaar Card', 'Bank Account', 'Vaccination Records'],
      category: 'Women & Children',
      applyLink: 'https://wcd.nic.in/pmmvy',
      icon: Icons.family_restroom,
    ),
    SchemeModel(
      id: '5',
      title: 'Pradhan Mantri Vaya Vandana Yojana',
      description: 'Pension scheme for senior citizens providing assured returns on investment.',
      benefits: 'Guaranteed pension income, 7.4% per annum interest rate, death benefit',
      eligibility: 'Senior citizens aged 60+ years, no upper age limit',
      documents: ['Aadhaar Card', 'PAN Card', 'Bank Account', 'Age Proof'],
      category: 'Senior Citizens',
      applyLink: 'https://licindia.in/Products/Pension-Plans/Pradhan-Mantri-Vaya-Vandana-Yojana',
      icon: Icons.elderly,
    ),
    SchemeModel(
      id: '6',
      title: 'Rashtriya Swasthya Bima Yojana',
      description: 'Health insurance scheme for Below Poverty Line (BPL) families.',
      benefits: '₹30,000 annual health cover, cashless treatment, pre-existing diseases covered',
      eligibility: 'BPL families, 5 members per family covered',
      documents: ['BPL Ration Card', 'Aadhaar Card', 'Family Photograph'],
      category: 'Healthcare',
      applyLink: 'https://rsby.gov.in/',
      icon: Icons.health_and_safety,
    ),
    SchemeModel(
      id: '7',
      title: 'Niramaya Health Insurance Scheme',
      description: 'Health insurance scheme for Persons with Autism, Cerebral Palsy, Mental Retardation, and Multiple Disabilities.',
      benefits: '₹1 lakh health cover, no age limit, covers OPD and hospitalization',
      eligibility: 'Persons with specified disabilities, registration with NIMH',
      documents: ['Disability Certificate', 'Aadhaar Card', 'Income Certificate'],
      category: 'Disability',
      applyLink: 'https://theni trust.org/niramaya',
      icon: Icons.accessibility_new,
    ),
    SchemeModel(
      id: '8',
      title: 'POSHAN Abhiyaan',
      description: 'Scheme to address malnutrition issues among children and pregnant/lactating mothers.',
      benefits: 'Nutritional support, health checkups, awareness programs',
      eligibility: 'Children under 6 years, pregnant/lactating mothers',
      documents: ['Aadhaar Card', 'Anganwadi Registration'],
      category: 'Women & Children',
      applyLink: 'https://poshanabhiyaan.gov.in/',
      icon: Icons.restaurant,
    ),
    SchemeModel(
      id: '9',
      title: 'National Dialysis Program',
      description: 'Free dialysis services for Below Poverty Line (BPL) patients.',
      benefits: 'Free dialysis treatment at government hospitals, PPP model facilities',
      eligibility: 'BPL patients with kidney failure, valid medical prescription',
      documents: ['Medical Certificate', 'BPL Certificate', 'Aadhaar Card'],
      category: 'Healthcare',
      applyLink: 'https://nhm.gov.in/',
      icon: Icons.medical_services,
    ),
    SchemeModel(
      id: '10',
      title: 'Senior Citizens Health Insurance',
      description: 'Health insurance specifically designed for senior citizens with coverage for age-related ailments.',
      benefits: 'Coverage up to ₹2 lakh, no pre-medical checkup for entry, renewal up to 80 years',
      eligibility: 'Indian citizens aged 60-80 years',
      documents: ['Age Proof', 'Aadhaar Card', 'Medical History'],
      category: 'Senior Citizens',
      applyLink: 'https://www.policybazaar.com/health-insurance/senior-citizen-health-insurance/',
      icon: Icons.health_and_safety,
    ),
  ];

  List<SchemeModel> get _filteredSchemes {
    var filtered = _schemes;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((s) => s.category == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) => 
        s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.benefits.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Government Schemes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: context.primaryText),
              decoration: InputDecoration(
                hintText: 'Search schemes...',
                hintStyle: TextStyle(color: context.secondaryText),
                prefixIcon: Icon(Icons.search, color: context.secondaryText),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: context.secondaryText),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Category Filter Chips
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: context.cardColor,
                    selectedColor: context.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : context.primaryText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Schemes List
          Expanded(
            child: _filteredSchemes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: context.secondaryText.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schemes found',
                          style: TextStyle(
                            fontSize: 18,
                            color: context.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.secondaryText.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredSchemes.length,
                    itemBuilder: (context, index) {
                      return _SchemeCard(scheme: _filteredSchemes[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SchemeCard extends StatefulWidget {
  final SchemeModel scheme;

  const _SchemeCard({required this.scheme});

  @override
  State<_SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<_SchemeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: context.cardColor,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.scheme.icon,
                      color: context.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.scheme.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.primaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.scheme.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: context.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: context.secondaryText,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Details
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 8),
                  const SizedBox(height: 8),
                  
                  _DetailSection(
                    icon: Icons.description,
                    title: 'Description',
                    content: widget.scheme.description,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _DetailSection(
                    icon: Icons.star,
                    title: 'Benefits',
                    content: widget.scheme.benefits,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _DetailSection(
                    icon: Icons.verified_user,
                    title: 'Eligibility',
                    content: widget.scheme.eligibility,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Documents Required
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.folder, size: 18, color: context.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Documents Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.primaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.scheme.documents.map((doc) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                doc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(widget.scheme.applyLink);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot open: ${widget.scheme.applyLink}'),
                              backgroundColor: context.errorColor,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Apply Now / Learn More'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.primaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SchemeModel {
  final String id;
  final String title;
  final String description;
  final String benefits;
  final String eligibility;
  final List<String> documents;
  final String category;
  final String applyLink;
  final IconData icon;

  SchemeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.benefits,
    required this.eligibility,
    required this.documents,
    required this.category,
    required this.applyLink,
    required this.icon,
  });
}