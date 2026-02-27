import '../../models/nas_source.dart';
import 'nas_service.dart';
import 'smb_nas_service.dart';
import 'webdav_nas_service.dart';

class NasServiceFactory {
  NasService create(NasSource source) {
    switch (source.protocol) {
      case NasProtocol.smb:
        return SmbNasService(source);
      case NasProtocol.webdav:
        return WebDavNasService(source);
    }
  }
}
