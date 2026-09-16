/*
 * Minimal replacement for `security find-generic-password -D desc -a account
 * -s service -w`, built natively for arm64/x86_64.
 *
 * Historically this helper was produced by lipo-thinning Apple's own
 * /usr/bin/security down to its x86_64 slice and ad-hoc re-signing it with a
 * custom identifier, purely so the System keychain ACL could trust this one
 * specific binary (see files/update.sh) without granting blanket access to
 * every process that happens to be /usr/bin/security. Apple's Mach-O for
 * /usr/bin/security only ships x86_64 and arm64e slices, and non-Apple
 * ad-hoc signatures of the arm64e slice fail the kernel's pointer
 * authentication ABI check, so the x86_64 slice needed Rosetta. Compiling
 * this ourselves for plain arm64 sidesteps that restriction entirely while
 * keeping the same custom-identity trust model.
 */

#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <stdio.h>
#include <string.h>

static void usage(const char *prog) {
	fprintf(stderr, "usage: %s find-generic-password -s service -a account [-D description] -w\n", prog);
}

int main(int argc, char *argv[]) {
	if (argc < 2 || strcmp(argv[1], "find-generic-password") != 0) {
		usage(argv[0]);
		return 2;
	}

	const char *service = NULL, *account = NULL, *description = NULL;
	int want_password = 0;

	for (int i = 2; i < argc; i++) {
		if (strcmp(argv[i], "-s") == 0 && i + 1 < argc) {
			service = argv[++i];
		} else if (strcmp(argv[i], "-a") == 0 && i + 1 < argc) {
			account = argv[++i];
		} else if (strcmp(argv[i], "-D") == 0 && i + 1 < argc) {
			description = argv[++i];
		} else if (strcmp(argv[i], "-w") == 0) {
			want_password = 1;
		}
	}

	if (!service || !account || !want_password) {
		usage(argv[0]);
		return 2;
	}

	SecKeychainRef systemKeychain = NULL;
	if (SecKeychainOpen("/Library/Keychains/System.keychain", &systemKeychain) != errSecSuccess || !systemKeychain) {
		return 1;
	}

	CFStringRef serviceStr = CFStringCreateWithCString(kCFAllocatorDefault, service, kCFStringEncodingUTF8);
	CFStringRef accountStr = CFStringCreateWithCString(kCFAllocatorDefault, account, kCFStringEncodingUTF8);
	CFStringRef descriptionStr = description
		? CFStringCreateWithCString(kCFAllocatorDefault, description, kCFStringEncodingUTF8)
		: NULL;
	CFArrayRef searchList = CFArrayCreate(kCFAllocatorDefault, (const void **)&systemKeychain, 1, &kCFTypeArrayCallBacks);

	CFMutableDictionaryRef query = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
		&kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(query, kSecClass, kSecClassGenericPassword);
	CFDictionarySetValue(query, kSecAttrService, serviceStr);
	CFDictionarySetValue(query, kSecAttrAccount, accountStr);
	if (descriptionStr) {
		CFDictionarySetValue(query, kSecAttrDescription, descriptionStr);
	}
	CFDictionarySetValue(query, kSecMatchSearchList, searchList);
	CFDictionarySetValue(query, kSecMatchLimit, kSecMatchLimitOne);
	CFDictionarySetValue(query, kSecReturnData, kCFBooleanTrue);

	CFTypeRef result = NULL;
	OSStatus status = SecItemCopyMatching(query, &result);

	CFRelease(query);
	CFRelease(searchList);
	CFRelease(serviceStr);
	CFRelease(accountStr);
	if (descriptionStr) {
		CFRelease(descriptionStr);
	}
	CFRelease(systemKeychain);

	if (status != errSecSuccess || !result) {
		return 1;
	}

	CFDataRef data = (CFDataRef)result;
	fwrite(CFDataGetBytePtr(data), 1, (size_t)CFDataGetLength(data), stdout);
	CFRelease(result);
	return 0;
}
