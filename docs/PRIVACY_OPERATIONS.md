# Madar Al-Huda privacy operations

Public policy: https://quran.abdulrahmanalsaeed.com/privacy/

Public deletion request: https://quran.abdulrahmanalsaeed.com/privacy/#request

The bilingual web page submits privacy requests to the existing private feedback inbox, tagged [Privacy request: ...]. This is a request intake, not automatic account deletion.

Owner responsibilities before public Play release:
- Review the text and verify the developer identity and data disclosures against the production app and providers.
- Review the privacy request inbox regularly; acknowledge and verify ownership via the account's established email, never request passwords or one-time codes.
- For verified account deletion, delete the corresponding Supabase Auth user and associated account records using authorized admin access; remove related feedback and attachments when identifiable and requested. Do not delete the person's Google account. Document any retention required for security/legal reasons, and rotate backups according to an approved retention schedule. Do not treat sign-out as deletion.
- Confirm a working contact mechanism and establish response and retention procedures. Do not claim automated account deletion or completed requests until the actual deletion is verified.
- Test the public form and settings links with a dedicated test account before Play submission. Complete Data safety separately based on actual production behavior.
