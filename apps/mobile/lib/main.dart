import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

part 'src/core/models/challenge_models.dart';
part 'src/core/network/api_client.dart';
part 'src/shared/extensions/challenge_type_ui.dart';
part 'src/shared/widgets/common_widgets.dart';
part 'src/app/security/screen_security_controller.dart';
part 'src/app/challenge_app.dart';
part 'src/features/auth/presentation/auth_screen.dart';
part 'src/features/home/presentation/home_screen.dart';
part 'src/features/challenges/presentation/challenges_screen.dart';
part 'src/features/challenges/presentation/challenge_run_screen.dart';
part 'src/features/challenges/presentation/challenge_helpers.dart';
part 'src/features/camera/presentation/camera_capture_screen.dart';
part 'src/features/reports/services/pdf_report_service.dart';
part 'src/features/reports/presentation/pdf_preview_screen.dart';
part 'src/features/ranking/presentation/ranking_screen.dart';
part 'src/features/profile/presentation/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChallengeApp());
}
