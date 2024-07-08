import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../controllers/drawer_navigation-controller.dart';
import '../../network/models/userprofile_model.dart';
import '../../routes/app_pages.dart';

class CAccounts extends StatefulWidget {
  final UserProfile? userProfile;

  CAccounts({this.userProfile});

  @override
  State<CAccounts> createState() => _CAccountsState();
}

class _CAccountsState extends State<CAccounts> {
  final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
  late bool logoutInitiated;
  int videoCount = 0;

  @override
  void initState() {
    super.initState();
    logoutInitiated = false;
    _fetchUserProfile();
    _fetchVideoCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<UserProfile?>(
                future: _getUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return _buildProfileForm(snapshot.data!);
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!logoutInitiated) {
                        _initiateLogout();
                      }
                    });
                    return Container();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<UserProfile?> _getUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _controller.userProfile;
  }

  Future<void> _fetchUserProfile() async {
    final box = GetStorage();
    try {
      var response = await http.get(
        Uri.parse('https://api.cuvasol.com/api/profile'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == true) {
          var profile = UserProfile.fromJson(data['data']);
          _controller.userProfile = profile;
          setState(() {});
        }
      } else {
        print('Failed to fetch user profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchUpdatedUserProfile() async {
    final box = GetStorage();
    final token = box.read('token');
    print('Fetching updated user profile with token: $token');
    try {
      var response = await http.get(
        Uri.parse('https://api.cuvasol.com/api/get/userprofile'),
        headers: {
          'Authorization': 'Bearer ${box.read('token')}',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == true) {
          var profile = UserProfile.fromJson(data['data']);
          _controller.userProfile = profile;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile successfully updated')),
          );
        }
      } else {
        print('Failed to fetch updated user profile. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server issues, check again later')),
        );
      }
    } catch (e) {
      print('Error fetching updated user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching updated user profile: $e')),
      );
    }
  }

  Future<void> _fetchVideoCount() async {
    final box = GetStorage();
    final token = box.read('token');
    print('Fetching video count with token: $token');
    try {
      var response = await http.get(
        Uri.parse('https://api.cuvasol.com/api/videos/limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            videoCount = data['data']['video_count'];
          });
        }
      } else {
        print('Failed to fetch video count. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching video count: $e');
    }
  }

  Widget _buildProfileForm(UserProfile profile) {
    final nameController = TextEditingController(text: profile.data?.name);
    final emailController = TextEditingController(text: profile.data?.contactEmail);
    final phoneController = TextEditingController(text: profile.data?.phoneNumber);
    final majorController = TextEditingController(text: profile.data?.major);
    final degreeController = TextEditingController(text: profile.data?.degree);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEditableField('Name', nameController),
        _buildEditableField('Email', emailController),
        _buildEditableField('Phone Number', phoneController),
        _buildEditableField('Major', majorController),
        _buildEditableField('Degree', degreeController),
        const SizedBox(height: 20),
        _buildVideoCountField(),
        const SizedBox(height: 40),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton('Update Account', Icons.update, () {
                _updateProfile(nameController.text, emailController.text, phoneController.text, majorController.text, degreeController.text);
              }),
              const SizedBox(width: 10),
              _buildActionButton('Delete Account', Icons.delete, () {
                _showDeleteAccountDialog();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black),
            ],
          ),
          const Divider(
            color: Colors.grey, // Set the color of the line to grey
            thickness: 1.5, // Set the thickness of the line
            height: 8, // Set the space above and below the line
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCountField() {
    return Text(
      'Number of Videos: $videoCount',
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xffe56b14)),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        primary: Colors.white,
        onPrimary: Colors.black,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        side: const BorderSide(color: Color(0xffe56b14)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to delete your account?',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteAccount();
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _updateProfile(String name, String email, String phone, String major, String degree) async {
    final box = GetStorage();
    final token = box.read('token');
    print('Updating profile with token: $token');
    try {
      var response = await http.post(
        Uri.parse('https://api.cuvasol.com/api/profile/create'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'name': name,
          'contact_email': email,
          'phone_number': phone,
          'major': major,
          'degree': degree,
        },
      );

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == true) {
          print('User Profile created Successfully. Verification code: ${data['data']['code']}');
          await _fetchUpdatedUserProfile();
        }
      } else {
        print('Failed to update profile. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server issues, check again later')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final box = GetStorage();
    final token = box.read('token');
    print('Deleting account with token: $token');
    try {
      var response = await http.post(
        Uri.parse('https://api.cuvasol.com/api/delete'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        var data = jsonDecode(response.body);
        if (data['status'] == true) {
          box.remove("token");
          box.remove("login");
          Get.offAllNamed(Routes.LOGIN);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account successfully deleted')),
          );
        }
      } else {
        print('Failed to delete account. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server issues, check again later')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _initiateLogout() {
    logoutInitiated = true;
    //Get.offAllNamed(Routes.LOGIN);
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import '../../controllers/drawer_navigation-controller.dart';
// import '../../network/models/userprofile_model.dart';
// import '../../routes/app_pages.dart';
//
// class CAccounts extends StatefulWidget {
//   final UserProfile? userProfile;
//
//   CAccounts({this.userProfile});
//
//   @override
//   State<CAccounts> createState() => _CAccountsState();
// }
//
// class _CAccountsState extends State<CAccounts> {
//   final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
//   late bool logoutInitiated;
//   int videoCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     logoutInitiated = false;
//     _fetchUserProfile();
//     _fetchVideoCount();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Profile',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FutureBuilder<UserProfile?>(
//                 future: _getUserProfile(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return _buildProfileForm(snapshot.data!);
//                   } else {
//                     WidgetsBinding.instance.addPostFrameCallback((_) {
//                       if (!logoutInitiated) {
//                         _initiateLogout();
//                       }
//                     });
//                     return Container();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<UserProfile?> _getUserProfile() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     return _controller.userProfile;
//   }
//
//   Future<void> _fetchUserProfile() async {
//     final box = GetStorage();
//     try {
//       var response = await http.get(
//         Uri.parse('https://api.cuvasol.com/api/profile'),
//         headers: {
//           'Authorization': 'Bearer ${box.read('token')}',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           var profile = UserProfile.fromJson(data['data']);
//           _controller.userProfile = profile;
//           setState(() {});
//         }
//       } else {
//         print('Failed to fetch user profile. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching user profile: $e');
//     }
//   }
//
//   Future<void> _fetchUpdatedUserProfile() async {
//     final box = GetStorage();
//     final token = box.read('token');
//     print('Fetching updated user profile with token: $token');
//     try {
//       var response = await http.get(
//         Uri.parse('https://api.cuvasol.com/api/get/userprofile'),
//         headers: {
//           'Authorization': 'Bearer ${box.read('token')}',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           var profile = UserProfile.fromJson(data['data']);
//           _controller.userProfile = profile;
//           setState(() {});
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Profile successfully updated')),
//           );
//         }
//       } else {
//         print('Failed to fetch updated user profile. Status code: ${response.statusCode}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error fetching updated user profile: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching updated user profile: $e')),
//       );
//     }
//   }
//
//   Future<void> _fetchVideoCount() async {
//     final box = GetStorage();
//     final token = box.read('token');
//     print('Fetching video count with token: $token');
//     try {
//       var response = await http.get(
//         Uri.parse('https://api.cuvasol.com/api/videos/limit'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           setState(() {
//             videoCount = data['data']['video_count'];
//           });
//         }
//       } else {
//         print('Failed to fetch video count. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching video count: $e');
//     }
//   }
//
//   Widget _buildProfileForm(UserProfile profile) {
//     final nameController = TextEditingController(text: profile.data?.name);
//     final emailController = TextEditingController(text: profile.data?.contactEmail);
//     final phoneController = TextEditingController(text: profile.data?.phoneNumber);
//     final majorController = TextEditingController(text: profile.data?.major);
//     final degreeController = TextEditingController(text: profile.data?.degree);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTextField('Name', nameController),
//         const SizedBox(height: 20),
//         _buildTextField('Email Id', emailController),
//         const SizedBox(height: 20),
//         _buildTextField('Phone Number', phoneController),
//         const SizedBox(height: 20),
//         _buildTextField('Major', majorController),
//         const SizedBox(height: 20),
//         _buildTextField('Degree', degreeController),
//         const SizedBox(height: 20),
//         _buildVideoCountField(),
//         const SizedBox(height: 40),
//         Center(
//           child: Column(
//             children: [
//               _buildActionButton('Update', Icons.update, () {
//                 _updateProfile(nameController.text, emailController.text, phoneController.text, majorController.text, degreeController.text);
//               }),
//               const SizedBox(height: 10),
//               _buildActionButton('Delete Account', Icons.delete, () {
//                 _showDeleteAccountDialog();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black54),
//         focusedBorder: const UnderlineInputBorder(
//           borderSide: BorderSide(color: Color(0xffe56b14)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildVideoCountField() {
//     return Text(
//       'Number of Videos: $videoCount',
//       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: const Color(0xffe56b14)),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         primary: Colors.white,
//         onPrimary: Colors.black,
//         textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//         side: const BorderSide(color: Color(0xffe56b14)),
//       ),
//     );
//   }
//
//   void _showDeleteAccountDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Account'),
//         content: const Text('Are you sure you want to delete your account?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               _deleteAccount();
//               Navigator.pop(context);
//             },
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _updateProfile(String name, String email, String phone, String major, String degree) async {
//     final box = GetStorage();
//     final token = box.read('token');
//     print('Updating profile with token: $token');
//     try {
//       var response = await http.post(
//         Uri.parse('https://api.cuvasol.com/api/profile/create'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//         body: {
//           'name': name,
//           'contact_email': email,
//           'phone_number': phone,
//           'major': major,
//           'degree': degree,
//         },
//       );
//
//       if (response.statusCode == 201) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           print('User Profile created Successfully. Verification code: ${data['data']['code']}');
//           await _fetchUpdatedUserProfile();
//         }
//       } else {
//         print('Failed to update profile. Status code: ${response.statusCode}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _deleteAccount() async {
//     final box = GetStorage();
//     final token = box.read('token');
//     print('Deleting account with token: $token');
//     try {
//       var response = await http.post(
//         Uri.parse('https://api.cuvasol.com/api/delete'),
//         headers: {
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       if (response.statusCode == 201) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           box.remove("token");
//           box.remove("login");
//           Get.offAllNamed(Routes.LOGIN);
//
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Account successfully deleted')),
//           );
//         }
//       } else {
//         print('Failed to delete account. Status code: ${response.statusCode}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   void _initiateLogout() {
//     logoutInitiated = true;
//     //Get.offAllNamed(Routes.LOGIN);
//   }
// }



// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import '../../controllers/drawer_navigation-controller.dart';
// import '../../network/models/userprofile_model.dart';
// import '../../routes/app_pages.dart';
//
// class CAccounts extends StatefulWidget {
//   final UserProfile? userProfile;
//
//   CAccounts({this.userProfile});
//
//   @override
//   State<CAccounts> createState() => _CAccountsState();
// }
//
// class _CAccountsState extends State<CAccounts> {
//   final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
//   late bool logoutInitiated;
//   int videoCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     logoutInitiated = false;
//     _checkUserData();
//     _fetchVideoCount();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FutureBuilder<UserProfile?>(
//                 future: _getUserProfile(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return _buildProfileForm(snapshot.data!);
//                   } else {
//                     WidgetsBinding.instance?.addPostFrameCallback((_) {
//                       if (!logoutInitiated) {
//                         _initiateLogout();
//                       }
//                     });
//                     return Container();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<UserProfile?> _getUserProfile() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 13));
//     print('Fetched user profile: ${_controller.userProfile}');
//     return _controller.userProfile;
//   }
//
//   Future<void> _fetchVideoCount() async {
//     final box = GetStorage();
//     try {
//       var response = await http.get(
//         Uri.parse('https://api.cuvasol.com/api/videos/limit'),
//         headers: {
//           'Authorization': 'Bearer ${box.read('token')}',
//         },
//       );
//
//       if (response.statusCode == 200) {
//         var data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           setState(() {
//             videoCount = data['data']['video_count'];
//           });
//         }
//       } else {
//         print('Failed to fetch video count. Status code: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching video count: $e');
//     }
//   }
//
//   Widget _buildProfileForm(UserProfile profile) {
//     print('Building profile form with: ${profile.data}');
//     TextEditingController nameController = TextEditingController(text: profile.data?.name);
//     TextEditingController emailController = TextEditingController(text: profile.data?.contactEmail);
//     TextEditingController phoneController = TextEditingController(text: profile.data?.phoneNumber);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTextField('Name', nameController),
//         const SizedBox(height: 20),
//         _buildTextField('Email I\'d', emailController),
//         const SizedBox(height: 20),
//         _buildPhoneField('Phone Number', phoneController),
//         const SizedBox(height: 20),
//         _buildVideoCountField(),
//         const SizedBox(height: 40),
//         Center(
//           child: Column(
//             children: [
//               _buildActionButton('Update', Icons.update, () {
//                 _updateProfile(nameController.text, emailController.text, phoneController.text);
//               }),
//               const SizedBox(height: 10),
//               _buildActionButton('Delete Account', Icons.delete, () {
//                 _showDeleteAccountDialog();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black54),
//         focusedBorder: const UnderlineInputBorder(
//           borderSide: BorderSide(color: Color(0xffe56b14)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPhoneField(String label, TextEditingController controller) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(color: Colors.black54),
//               focusedBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Color(0xffe56b14)),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         ElevatedButton(
//           onPressed: () {
//             _updatePhoneNumber(controller.text);
//           },
//           child: const Text('Update Phone Number'),
//           style: ElevatedButton.styleFrom(
//             primary: const Color(0xffe56b14),
//             onPrimary: Colors.white,
//             textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildVideoCountField() {
//     return Text(
//       'Number of Videos: $videoCount',
//       style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: const Color(0xffe56b14)),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         primary: Colors.white,
//         onPrimary: const Color(0xffe56b14),
//         textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: const BorderSide(color: Color(0xff030303)),
//         minimumSize: const Size(200, 50),
//       ),
//     );
//   }
//
//   Future<void> _updatePhoneNumber(String phone) async {
//     await _updateProfile(
//       _controller.userProfile!.data!.name ?? "",
//       _controller.userProfile!.data!.contactEmail ?? "",
//       phone,
//     );
//   }
//
//   void _showDeleteAccountDialog() {
//     Get.defaultDialog(
//       radius: 12,
//       title: 'Confirm Delete Account',
//       titleStyle: Theme.of(context).textTheme.headline6?.copyWith(
//         fontSize: 18,
//         color: Colors.black,
//         fontWeight: FontWeight.w800,
//       ),
//       middleText: 'Deleting your account will remove all of your information from Our Database, This cannot be undone',
//       middleTextStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
//         fontSize: 14,
//         color: Colors.black,
//         fontWeight: FontWeight.w500,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             _deleteAccount();
//           },
//           child: Text(
//             'Delete',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             Get.back();
//           },
//           child: Text(
//             'Cancel',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _updateProfile(String name, String email, String phone) async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/update'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//       request.bodyFields = {
//         'name': name,
//         'contact_email': email,
//         'phone_number': phone,
//       };
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profile successfully updated')),
//         );
//       } else {
//         print('Failed to update profile. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _deleteAccount() async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/delete'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 201) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         box.remove("token");
//         box.remove("login");
//         Get.offAllNamed(Routes.LOGIN);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Account successfully deleted')),
//         );
//       } else {
//         print('Failed to delete account. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _checkUserData() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (!logoutInitiated && (_controller.userProfile?.data?.name == null || _controller.userProfile?.data?.contactEmail == null)) {
//       _initiateLogout();
//     }
//   }
//
//   void _initiateLogout() {
//     logoutInitiated = true;
//     // UserRepo().logout();
//   }
//
//   void showSessionExpiredSnackBar() {
//     Get.snackbar(
//       "Session Expired...",
//       "Session has expired. Please login again.",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.black87,
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(20),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import '../../controllers/drawer_navigation-controller.dart';
// import '../../network/models/userprofile_model.dart';
// import '../../routes/app_pages.dart';
//
// class CAccounts extends StatefulWidget {
//   final UserProfile? userProfile;
//
//   CAccounts({this.userProfile});
//
//   @override
//   State<CAccounts> createState() => _CAccountsState();
// }
//
// class _CAccountsState extends State<CAccounts> {
//   final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
//   late bool logoutInitiated;
//
//   @override
//   void initState() {
//     super.initState();
//     logoutInitiated = false;
//     _checkUserData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FutureBuilder<UserProfile?>(
//                 future: _getUserProfile(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return _buildProfileForm(snapshot.data!);
//                   } else {
//                     WidgetsBinding.instance?.addPostFrameCallback((_) {
//                       if (!logoutInitiated) {
//                         _initiateLogout();
//                       }
//                     });
//                     return Container();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<UserProfile?> _getUserProfile() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 13));
//     print('Fetched user profile: ${_controller.userProfile}');
//     return _controller.userProfile;
//   }
//
//   Widget _buildProfileForm(UserProfile profile) {
//     print('Building profile form with: ${profile.data}');
//     TextEditingController nameController = TextEditingController(text: profile.data?.name);
//     TextEditingController emailController = TextEditingController(text: profile.data?.contactEmail);
//     TextEditingController phoneController = TextEditingController(text: profile.data?.phoneNumber);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTextField('Name', nameController),
//         const SizedBox(height: 20),
//         _buildTextField('Email I\'d', emailController),
//         const SizedBox(height: 20),
//         _buildPhoneField('Phone Number', phoneController),
//         const SizedBox(height: 40),
//         Center(
//           child: Column(
//             children: [
//               _buildActionButton('Update', Icons.update, () {
//                 _updateProfile(nameController.text, emailController.text, phoneController.text);
//               }),
//               const SizedBox(height: 10),
//               _buildActionButton('Delete Account', Icons.delete, () {
//                 _showDeleteAccountDialog();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black54),
//         focusedBorder: const UnderlineInputBorder(
//           borderSide: BorderSide(color: Color(0xffe56b14)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPhoneField(String label, TextEditingController controller) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             controller: controller,
//             decoration: InputDecoration(
//               labelText: label,
//               labelStyle: const TextStyle(color: Colors.black54),
//               focusedBorder: const UnderlineInputBorder(
//                 borderSide: BorderSide(color: Color(0xffe56b14)),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),
//         ElevatedButton(
//           onPressed: () {
//             _updatePhoneNumber(controller.text);
//           },
//           child: const Text('Update Phone Number'),
//           style: ElevatedButton.styleFrom(
//             primary: const Color(0xffe56b14),
//             onPrimary: Colors.white,
//             textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: const Color(0xffe56b14)),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         primary: Colors.white,
//         onPrimary: const Color(0xffe56b14),
//         textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: const BorderSide(color: Color(0xff030303)),
//         minimumSize: const Size(200, 50),
//       ),
//     );
//   }
//
//   Future<void> _updatePhoneNumber(String phone) async {
//     // Add logic to update the phone number
//     // You can reuse the _updateProfile function if appropriate
//     await _updateProfile(
//       _controller.userProfile!.data!.name ?? "",
//       _controller.userProfile!.data!.contactEmail ?? "",
//       phone,
//     );
//   }
//
//   void _showDeleteAccountDialog() {
//     Get.defaultDialog(
//       radius: 12,
//       title: 'Confirm Delete Account',
//       titleStyle: Theme.of(context).textTheme.headline6?.copyWith(
//         fontSize: 18,
//         color: Colors.black,
//         fontWeight: FontWeight.w800,
//       ),
//       middleText: 'Deleting your account will remove all of your information from Our Database, This cannot be undone',
//       middleTextStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
//         fontSize: 14,
//         color: Colors.black,
//         fontWeight: FontWeight.w500,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             _deleteAccount();
//           },
//           child: Text(
//             'Delete',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             Get.back();
//           },
//           child: Text(
//             'Cancel',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _updateProfile(String name, String email, String phone) async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/update'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//       request.bodyFields = {
//         'name': name,
//         'contact_email': email,
//         'phone_number': phone,
//       };
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profile successfully updated')),
//         );
//       } else {
//         print('Failed to update profile. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _deleteAccount() async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/delete'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 201) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         box.remove("token");
//         box.remove("login");
//         Get.offAllNamed(Routes.LOGIN);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Account successfully deleted')),
//         );
//       } else {
//         print('Failed to delete account. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _checkUserData() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (!logoutInitiated && (_controller.userProfile?.data?.name == null || _controller.userProfile?.data?.contactEmail == null)) {
//       _initiateLogout();
//     }
//   }
//
//   void _initiateLogout() {
//     logoutInitiated = true;
//     // UserRepo().logout();
//   }
//
//   void showSessionExpiredSnackBar() {
//     Get.snackbar(
//       "Session Expired...",
//       "Session has expired. Please login again.",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.black87,
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(20),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import '../../controllers/drawer_navigation-controller.dart';
// import '../../network/models/userprofile_model.dart';
// import '../../routes/app_pages.dart';
//
// class CAccounts extends StatefulWidget {
//   final UserProfile? userProfile;
//
//   CAccounts({this.userProfile});
//
//   @override
//   State<CAccounts> createState() => _CAccountsState();
// }
//
// class _CAccountsState extends State<CAccounts> {
//   final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
//   late bool logoutInitiated;
//
//   @override
//   void initState() {
//     super.initState();
//     logoutInitiated = false;
//     _checkUserData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FutureBuilder<UserProfile?>(
//                 future: _getUserProfile(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return _buildProfileForm(snapshot.data!);
//                   } else {
//                     WidgetsBinding.instance?.addPostFrameCallback((_) {
//                       if (!logoutInitiated) {
//                         _initiateLogout();
//                       }
//                     });
//                     return Container();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<UserProfile?> _getUserProfile() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 13));
//     print('Fetched user profile: ${_controller.userProfile}');
//     return _controller.userProfile;
//   }
//
//   Widget _buildProfileForm(UserProfile profile) {
//     print('Building profile form with: ${profile.data}');
//     TextEditingController nameController = TextEditingController(text: profile.data?.name);
//     TextEditingController emailController = TextEditingController(text: profile.data?.contactEmail);
//     TextEditingController phoneController = TextEditingController(text: profile.data?.phoneNumber);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTextField('Name', nameController),
//         const SizedBox(height: 20),
//         _buildTextField('Email I\'d', emailController),
//         const SizedBox(height: 20),
//         _buildTextField('Phone Number', phoneController),
//         const SizedBox(height: 40),
//         Center(
//           child: Column(
//             children: [
//               _buildActionButton('Update', Icons.update, () {
//                 _updateProfile(nameController.text, emailController.text, phoneController.text);
//               }),
//               const SizedBox(height: 10),
//               _buildActionButton('Delete Account', Icons.delete, () {
//                 _showDeleteAccountDialog();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black54),
//         focusedBorder: const UnderlineInputBorder(
//           borderSide: BorderSide(color: Color(0xffe56b14)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: const Color(0xffe56b14)),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         primary: Colors.white,
//         onPrimary: const Color(0xffe56b14),
//         textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: const BorderSide(color: Color(0xff030303)),
//         minimumSize: const Size(200, 50),
//       ),
//     );
//   }
//
//   void _showDeleteAccountDialog() {
//     Get.defaultDialog(
//       radius: 12,
//       title: 'Confirm Delete Account',
//       titleStyle: Theme.of(context).textTheme.headline6?.copyWith(
//         fontSize: 18,
//         color: Colors.black,
//         fontWeight: FontWeight.w800,
//       ),
//       middleText: 'Deleting your account will remove all of your information from Our Database, This cannot be undone',
//       middleTextStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
//         fontSize: 14,
//         color: Colors.black,
//         fontWeight: FontWeight.w500,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             _deleteAccount();
//           },
//           child: Text(
//             'Delete',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             Get.back();
//           },
//           child: Text(
//             'Cancel',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _updateProfile(String name, String email, String phone) async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/update'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//       request.bodyFields = {
//         'name': name,
//         'contact_email': email,
//         'phone_number': phone,
//       };
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Profile successfully updated')),
//         );
//       } else {
//         print('Failed to update profile. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _deleteAccount() async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/delete'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 201) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         box.remove("token");
//         box.remove("login");
//         Get.offAllNamed(Routes.LOGIN);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Account successfully deleted')),
//         );
//       } else {
//         print('Failed to delete account. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _checkUserData() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (!logoutInitiated && (_controller.userProfile?.data?.name == null || _controller.userProfile?.data?.contactEmail == null)) {
//       _initiateLogout();
//     }
//   }
//
//   void _initiateLogout() {
//     logoutInitiated = true;
//     // UserRepo().logout();
//   }
//
//   void showSessionExpiredSnackBar() {
//     Get.snackbar(
//       "Session Expired...",
//       "Session has expired. Please login again.",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.black87,
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(20),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import '../../controllers/drawer_navigation-controller.dart';
// import '../../network/models/userprofile_model.dart';
// import '../../routes/app_pages.dart';
//
// class CAccounts extends StatefulWidget {
//   final UserProfile? userProfile;
//
//   CAccounts({this.userProfile});
//
//   @override
//   State<CAccounts> createState() => _CAccountsState();
// }
//
// class _CAccountsState extends State<CAccounts> {
//   final DrawerNavigationController _controller = Get.put(DrawerNavigationController());
//   late bool logoutInitiated;
//
//   @override
//   void initState() {
//     super.initState();
//     logoutInitiated = false;
//     _checkUserData();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               FutureBuilder<UserProfile?>(
//                 future: _getUserProfile(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const CircularProgressIndicator();
//                   }
//                   if (snapshot.hasData && snapshot.data != null) {
//                     return _buildProfileForm(snapshot.data!);
//                   } else {
//                     WidgetsBinding.instance?.addPostFrameCallback((_) {
//                       if (!logoutInitiated) {
//                         _initiateLogout();
//                       }
//                     });
//                     return Container();
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<UserProfile?> _getUserProfile() async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 13));
//     print('Fetched user profile: ${_controller.userProfile}');
//     return _controller.userProfile;
//   }
//
//   Widget _buildProfileForm(UserProfile profile) {
//     print('Building profile form with: ${profile.data}');
//     TextEditingController nameController = TextEditingController(text: profile.data?.name);
//     TextEditingController emailController = TextEditingController(text: profile.data?.contactEmail);
//     TextEditingController phoneController = TextEditingController(text: profile.data?.phoneNumber);
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildTextField('Name', nameController),
//         const SizedBox(height: 20),
//         _buildTextField('Email I\'d', emailController),
//         const SizedBox(height: 20),
//         _buildTextField('Phone Number', phoneController),
//         const SizedBox(height: 40),
//         Center(
//           child: Column(
//             children: [
//               _buildActionButton('Update', Icons.update, () {
//                 // Implement your profile updating logic here
//               }),
//               const SizedBox(height: 10),
//               _buildActionButton('Delete Account', Icons.delete, () {
//                 _showDeleteAccountDialog();
//               }),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return TextField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         labelStyle: const TextStyle(color: Colors.black54),
//         focusedBorder: const UnderlineInputBorder(
//           borderSide: BorderSide(color: Color(0xffe56b14)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, color: const Color(0xffe56b14)),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         primary: Colors.white,
//         onPrimary: const Color(0xffe56b14),
//         textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
//         padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         side: const BorderSide(color: Color(0xff030303)),
//         minimumSize: const Size(200, 50),
//       ),
//     );
//   }
//
//   void _showDeleteAccountDialog() {
//     Get.defaultDialog(
//       radius: 12,
//       title: 'Confirm Delete Account',
//       titleStyle: Theme.of(context).textTheme.headline6?.copyWith(
//         fontSize: 18,
//         color: Colors.black,
//         fontWeight: FontWeight.w800,
//       ),
//       middleText: 'Deleting your account will remove all of your information from Our Database, This cannot be undone',
//       middleTextStyle: Theme.of(context).textTheme.subtitle1?.copyWith(
//         fontSize: 14,
//         color: Colors.black,
//         fontWeight: FontWeight.w500,
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             _deleteAccount();
//           },
//           child: Text(
//             'Delete',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//         TextButton(
//           onPressed: () {
//             Get.back();
//           },
//           child: Text(
//             'Cancel',
//             style: Theme.of(context).textTheme.button?.copyWith(
//               fontSize: 14,
//               color: const Color(0xffe56b14),
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _deleteAccount() async {
//     final box = GetStorage();
//     try {
//       var request = http.Request('POST', Uri.parse('https://api.cuvasol.com/api/delete'));
//       request.headers['Authorization'] = 'Bearer ${box.read('token')}';
//
//       http.StreamedResponse response = await request.send();
//
//       if (response.statusCode == 201) {
//         final responseBody = await response.stream.bytesToString();
//         print('Response body: $responseBody');
//
//         box.remove("token");
//         box.remove("login");
//         Get.offAllNamed(Routes.LOGIN);
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Account successfully deleted')),
//         );
//       } else {
//         print('Failed to delete account. Status code: ${response.statusCode}');
//         print('Reason phrase: ${response.reasonPhrase}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server issues, check again later')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     }
//   }
//
//   Future<void> _checkUserData() async {
//     await Future.delayed(const Duration(seconds: 1));
//     if (!logoutInitiated && (_controller.userProfile?.data?.name == null || _controller.userProfile?.data?.contactEmail == null)) {
//       _initiateLogout();
//     }
//   }
//
//   void _initiateLogout() {
//     logoutInitiated = true;
//     // UserRepo().logout();
//   }
//
//   void showSessionExpiredSnackBar() {
//     Get.snackbar(
//       "Session Expired...",
//       "Session has expired. Please login again.",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.black87,
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(20),
//       duration: const Duration(seconds: 3),
//     );
//   }
// }


