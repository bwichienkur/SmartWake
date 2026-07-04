namespace SmsPlatform.Domain.Common;

public static class OptOutKeywords
{
    public static readonly string[] Keywords = ["STOP", "UNSUBSCRIBE", "CANCEL", "END", "QUIT"];
}

public static class ComplianceConstants
{
    public static readonly TimeOnly QuietHoursStart = new(20, 0);
    public static readonly TimeOnly QuietHoursEnd = new(8, 0);
    public const int MaxMessagesPerNumberPerDay = 1000;
    public const int MaxMessagesPerNumberPerMinute = 15;
    public const double HighComplianceRiskThreshold = 0.7;
}

public static class PhoneNumberHelper
{
    public static string Normalize(string phoneNumber)
    {
        var digits = new string(phoneNumber.Where(char.IsDigit).ToArray());
        if (digits.Length == 10)
        {
            return $"+1{digits}";
        }

        return phoneNumber.StartsWith('+') ? phoneNumber : $"+{digits}";
    }

    public static string? InferUsTimezone(string phoneNumber)
    {
        var digits = new string(phoneNumber.Where(char.IsDigit).ToArray());
        if (digits.Length < 10)
        {
            return null;
        }

        var areaCode = int.Parse(digits[^10..^7]);
        return areaCode switch
        {
            >= 201 and <= 239 => "America/New_York",
            >= 480 and <= 520 => "America/Phoenix",
            >= 600 and <= 699 => "America/Chicago",
            >= 800 and <= 899 => "America/Denver",
            _ => "America/New_York"
        };
    }
}
