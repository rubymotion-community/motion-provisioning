/* 
 * This file contains modified code with copyright:
 *
 * Copyright (c) 2003-2010,2012,2014 Apple Inc. All Rights Reserved.
 *
 * Covered by the APPLE PUBLIC SOURCE LICENSE 
 * (http://opensource.apple.com/license/apsl/)
 */

#import <CoreFoundation/CoreFoundation.h>
#import <Security/Security.h>

#define DEBUG 0

unsigned char
hexValue(char c)
{
  static const char digits[] = "0123456789abcdef";
  char *p;
  if (p = strchr(digits, tolower(c)))
    return p - digits;
  else
    return 0;
}

void
fromHex(const char *hexDigits, CSSM_DATA *data)
{
  size_t bytes = strlen(hexDigits) / 2;	// (discards malformed odd end)
  if (bytes > data->Length)
    return;
  // length(bytes); // (will assert if we try to grow it)
  size_t n;
  for (n = 0; n < bytes; n++) {
    data->Data[n] = (uint8)(hexValue(hexDigits[2*n]) << 4 | hexValue(hexDigits[2*n+1]));
  }
}

int main(int argc, char *argv[]) {

  if (argc != 4) {
    exit(1);
  }

  char* identity_name = argv[1];
  char* hash = argv[2];
  char* key_password = argv[3];

  // First get a list of Identities matching the specified name
  const void* values[] = {
    kSecClassIdentity,
    kCFBooleanTrue,
    CFStringCreateWithCString(NULL, identity_name, kCFStringEncodingUTF8),
    kSecMatchLimitAll
  };
  const void* keys[] = {
    kSecClass,
    kSecReturnRef,
    kSecMatchSubjectContains,
    kSecMatchLimit
  };
  CFIndex numValues = sizeof(keys)/sizeof(void*);
  CFDictionaryRef query = CFDictionaryCreate(NULL, keys, values, numValues, NULL, NULL);

  CFTypeRef results;
  if (SecItemCopyMatching(query, &results) != noErr) {
    exit(1);
  }

  // Prepare the Identity hash
  CSSM_DATA hashData = { 0, NULL };
  CSSM_SIZE len = strlen(hash)/2;
  hashData.Length = len;
  hashData.Data = (uint8 *)malloc(hashData.Length);
  fromHex(hash, &hashData);

  SecIdentityRef item;
  CSSM_DATA certData = { 0, NULL };
  SecCertificateRef cert = NULL;
  Boolean found = FALSE;
  
  // Check all found identitied, looking for one whose certificate matches the
  // specified hash
  CFIndex count = CFArrayGetCount(results);
  for (int i = 0; i < count; i++) {
    item = CFArrayGetValueAtIndex(results, i);	
    
    if (SecIdentityCopyCertificate(item, &cert) != noErr) {
      CFRelease(&item);
      continue;
    }
    
    if (SecCertificateGetData(cert, &certData) != noErr) {
      CFRelease(&cert);
      CFRelease(&item);
      continue;
    }

    uint8 candidate_sha1_hash[20];
    CSSM_DATA digest;
    digest.Length = sizeof(candidate_sha1_hash);
    digest.Data = candidate_sha1_hash;
    if ((SecDigestGetData(CSSM_ALGID_SHA1, &digest, &certData) == CSSM_OK) &&
      (hashData.Length == digest.Length) &&
      (!memcmp(hashData.Data, digest.Data, digest.Length))) {
      found = TRUE;
      break;
    }
  }

  if (found) {
#if DEBUG
    CFStringRef nameRef = NULL;
    if (SecCertificateCopyCommonName(cert, &nameRef) != noErr) {
      exit(1);
    }

    char *cert_name = CFStringGetCStringPtr(nameRef, kCFStringEncodingUTF8);
    printf("%s\n", cert_name);
#endif
    
    // Finally, get the encrypted private key using the specified password
    // and print it to stdout in PEM format
    SecKeyRef key = NULL;
    if (SecIdentityCopyPrivateKey(item, &key) != noErr) {
      exit(1);
    }
  
    SecKeyImportExportParameters keyParams;
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = CFDataCreate(NULL, key_password, 5);
    keyParams.alertTitle = 0;
    keyParams.alertPrompt = 0;    
    
    CFDataRef key_data;
    OSStatus status = SecKeychainItemExport(key, kSecFormatWrappedPKCS8, 
        kSecItemPemArmour, &keyParams, &key_data);
  
    if(status == noErr) {
      write(fileno(stdout), CFDataGetBytePtr(key_data), CFDataGetLength(key_data));
    }
  }
}
