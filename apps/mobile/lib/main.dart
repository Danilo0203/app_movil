import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'src/core/models/challenge_models.dart';
part 'src/core/network/api_client.dart';
part 'src/core/offline/offline_models.dart';
part 'src/core/offline/local_database_service.dart';
part 'src/core/offline/offline_sync_queue_repository.dart';
part 'src/core/offline/connectivity_service.dart';
part 'src/core/offline/sync_manager.dart';
part 'src/core/offline/offline_app_controller.dart';
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
part 'src/features/profile/presentation/profile_edit_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ChallengeApp());
}
