import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App Mạng Xã Hội',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// =============================================================================
// QUẢN LÝ DỮ LIỆU TÀI KHOẢN (USER STORE)
// Lưu giữ Họ tên, Mật khẩu, Ảnh đại diện khi Đăng xuất & Đăng nhập lại
// =============================================================================
class UserProfile {
  String email;
  String password;
  String name;
  String studentId;
  String? avatarPath; // Đường dẫn ảnh cục bộ từ thư viện thiết bị
  String avatarUrl; // Giữ lại để tương thích với dữ liệu tài khoản hiện có

  UserProfile({
    required this.email,
    required this.password,
    this.name = '', // Ban đầu để trống theo yêu cầu
    this.studentId = '',
    this.avatarPath,
    this.avatarUrl = '',
  });
}

class UserStore {
  static final Map<String, UserProfile> _users = {};

  static UserProfile? getUser(String email) {
    return _users[email];
  }

  static UserProfile loginOrCreate(String email, String password) {
    if (!_users.containsKey(email)) {
      _users[email] = UserProfile(
        email: email,
        password: password,
        name: '', // Ban đầu để trống
      );
    }
    return _users[email]!;
  }

  static void updateUser(UserProfile profile) {
    _users[profile.email] = profile;
  }
}

// =============================================================================
// 1. MÀN HÌNH ĐĂNG NHẬP (LOGIN SCREEN)
// =============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final existingUser = UserStore.getUser(email);
      if (existingUser != null && existingUser.password != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu không chính xác!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final userProfile = UserStore.loginOrCreate(email, password);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(userProfile: userProfile),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FC), //[cite: 1]
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đăng nhập', //[cite: 1]
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ô nhập Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email', //[cite: 1]
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập Email';
                      }
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email không đúng định dạng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ô nhập Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true, //[cite: 1]
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu', //[cite: 1]
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng nhập
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Đăng nhập', //[cite: 1]
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. MÀN HÌNH DASHBOARD (BOTTOM NAVIGATION BAR)
// =============================================================================
class DashboardScreen extends StatefulWidget {
  final UserProfile userProfile;

  const DashboardScreen({super.key, required this.userProfile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      ProfilePage(userProfile: widget.userProfile),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Bảng tin Trang chủ' : 'Hồ sơ cá nhân',
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}

// =============================================================================
// 3. TRANG CHỦ (HOME PAGE - FEED MẠNG XÃ HỘI)
// =============================================================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> posts = [
      {
        'author': 'Sopii',
        'avatarUrl': 'https://photo-baomoi.bmcdn.me/w500_r1/2026_09_24_20_56117393/15b30fc8ba8353dd0a92.jpg',
        'time': '5 phút trước',
        'content': 'Thank you everyone! ❤️❤️😘 #PUBG #BattleRoyale',
        'likes': 12,
        'comments': 3,
        'hasImage': true,
        'imageUrl': 'https://i.ytimg.com/an_webp/jdM3MoOrgb8/mqdefault_6s.webp?du=3000&sqp=CPS7kdYG&rs=AOn4CLBI-HpYjf2BitZueuAPqWvXDrPQ5w',
      },
      {
        'author': 'Lã Phương Tiến Đạt',
        'avatarUrl': 'https://scontent.fsgn2-9.fna.fbcdn.net/v/t39.30808-1/742606471_122254499222088316_1116677582186169515_n.jpg?stp=dst-jpg_tt6&cstp=mx960x960&ctp=s200x200&_nc_cat=108&_nc_map=urlgen_bucketless&ccb=1-7&_nc_sid=2d3e12&_nc_ohc=lp8cnSzNYIcQ7kNvwF5jrC3&_nc_oc=AdrgwhI1LG3oE-5Ch9pOOdxLKwShVDItGzNWhN1eJcdt_W4de36UmTn0QJVubseSDZU&_nc_zt=24&_nc_ht=scontent.fsgn2-9.fna&_nc_gid=yEl73cQdhpSiNZeDTV8hYw&_nc_ss=7b2a8&oh=00_AQM0OV4CyC77kkUeT8ydgcmmv0tnRF34yTfjh5310y-sDg&oe=6ACA3868',
        'time': '1 giờ trước',
        'content': 'CHÍNH THỨC THẤT NGHIỆP! 😭😭😭',
        'likes': 199,
        'comments': 95,
        'hasImage': false,
        'imageUrl': '',
      },
      {
        'author': 'MixiGaming',
        'avatarUrl': 'https://scontent.fsgn2-10.fna.fbcdn.net/v/t1.6435-9/155836987_279784560163310_4097811254850609460_n.jpg?stp=dst-jpg_tt6&cstp=mx500x500&ctp=s500x500&_nc_cat=1&ccb=1-7&_nc_sid=6ee11a&_nc_ohc=Gceavlb6POcQ7kNvwGS_8RV&_nc_oc=AdoFzZOVWaHgJGjSIO-yQiY6HL3q0qZRtq-DtF4b72S6_O9k-uxx3-PGZmEv7uAuJ-Y&_nc_zt=23&_nc_ht=scontent.fsgn2-10.fna&_nc_gid=hVWULe8CZ5I3NJgX5uU3tQ&_nc_ss=7b2a8&oh=00_AQMkEj5kaImBjW4YYmVMjuZFWwZtUT0WBDUxpP9X2dyAng&oe=6AEBCBF8',
        'time': '3 giờ trước',
        'content': 'Từ nay Độ đã có thể nằm trên giường và nuôi\nkhủng long với MSI Claw 8 Ex 🦖🦖🦖\n#MSI',
        'likes': 64,
        'comments': 9,
        'hasImage': true,
        'imageUrl': 'https://scontent.fsgn2-5.fna.fbcdn.net/v/t39.30808-6/810149830_1630691835072569_4164834300515923947_n.jpg?stp=dst-jpg_tt6&cstp=mx2048x1152&ctp=s2048x1152&_nc_cat=104&_nc_map=urlgen_bucketless&ccb=1-7&_nc_sid=833d8c&_nc_ohc=XR9TjubDPqAQ7kNvwFY3zHl&_nc_oc=Adpj-ATySI_UCACF9P-GM8jHzw0Jr5vXhGqj-DMnH07CTVn1oF_CuXjwhQ2phyPEEgA&_nc_zt=23&_nc_ht=scontent.fsgn2-5.fna&_nc_gid=PdZGtPm7o4AdTMXj_U8rOQ&_nc_ss=7b2a8&oh=00_AQOVwF_xHyGIEWUOFDRFNFyGwRN6BgNy2FIS6-DmaJc3xA&oe=6ACA31DF',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: posts[index]);
      },
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class VideoPostMedia extends StatefulWidget {
  final String videoUrl;

  const VideoPostMedia({super.key, required this.videoUrl});

  @override
  State<VideoPostMedia> createState() => _VideoPostMediaState();
}

class _VideoPostMediaState extends State<VideoPostMedia> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideo = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeVideo,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 200,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Text('Không thể tải video'),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_controller),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    likeCount = widget.post['likes'];
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post['avatarUrl']),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['author'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      post['time'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post['content'],
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 10),
            if (post['videoUrl'] != null) ...[
              VideoPostMedia(videoUrl: post['videoUrl']),
              const SizedBox(height: 10),
            ] else if (post['hasImage']) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  post['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[700],
                  ),
                  label: Text(
                    '$likeCount Thích',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.grey[700],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.comment_outlined, color: Colors.grey[700]),
                  label: Text(
                    '${post['comments']} Bình luận',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.share_outlined, color: Colors.grey[700]),
                  label: Text(
                    'Chia sẻ',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 4. TRANG HỒ SƠ (PROFILE PAGE)
// =============================================================================
class ProfilePage extends StatefulWidget {
  final UserProfile userProfile;

  const ProfilePage({super.key, required this.userProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _studentIdController = TextEditingController(
      text: widget.userProfile.studentId,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  // 1. Chọn ảnh đại diện từ thư viện ảnh thiết bị (ImagePicker)
  Future<void> _pickAvatarFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        widget.userProfile.avatarPath = image.path;
        UserStore.updateUser(widget.userProfile);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chọn ảnh đại diện từ thư viện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Hiển thị ảnh đã chọn; nếu chưa có thì hiển thị icon mặc định.
  Widget _buildAvatarWidget() {
    if (widget.userProfile.avatarPath != null &&
        widget.userProfile.avatarPath!.isNotEmpty) {
      return CircleAvatar(
        radius: 55,
        backgroundImage: FileImage(File(widget.userProfile.avatarPath!)),
      );
    }
    return CircleAvatar(
      radius: 55,
      backgroundColor: Colors.grey.shade300,
      child: Icon(Icons.person, size: 64, color: Colors.grey.shade700),
    );
  }

  // 2. Đổi mật khẩu
  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu cũ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu cũ';
                      }
                      if (value != widget.userProfile.password) {
                        return 'Mật khẩu cũ không chính xác!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu mới';
                      }
                      if (value.length < 6) {
                        return 'Mật khẩu mới phải có ít nhất 6 ký tự';
                      }
                      if (value == widget.userProfile.password) {
                        return 'Mật khẩu mới phải khác mật khẩu cũ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != newPasswordController.text) {
                        return 'Xác nhận mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    widget.userProfile.password = newPasswordController.text;
                    UserStore.updateUser(widget.userProfile);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đổi mật khẩu thành công!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // 3. Đăng xuất
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // --- 1. Mục Ảnh Đại Diện (Chọn từ thư viện) ---
          Stack(
            children: [
              _buildAvatarWidget(),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickAvatarFromGallery, // Gọi hàm chọn ảnh từ thư viện
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library, // Icon thư viện
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- 2. Mục Họ và Tên (Tự động lưu khi gõ, không cần nút xác nhận) ---
          TextField(
            controller: _nameController,
            onChanged: (value) {
              // Tự động lưu tên ngay khi người dùng gõ
              widget.userProfile.name = value;
              UserStore.updateUser(widget.userProfile);
            },
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'Nhập họ và tên của bạn...',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 3. Mục Mã số sinh viên (Tự động lưu khi gõ) ---
          TextField(
            controller: _studentIdController,
            onChanged: (value) {
              widget.userProfile.studentId = value;
              UserStore.updateUser(widget.userProfile);
            },
            decoration: InputDecoration(
              labelText: 'Mã số sinh viên',
              hintText: 'Nhập mã số sinh viên của bạn...',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 4. Mục Địa chỉ Email (Đã đăng nhập) ---
          TextField(
            controller: TextEditingController(text: widget.userProfile.email),
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Địa chỉ Email (Đã đăng nhập)',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),

          // --- 5. Ô Đổi mật khẩu ---
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- 6. Ô Đăng xuất ---
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Đăng xuất',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
