using System.Globalization;
using UnityEngine;

/// <summary>
/// Cross-platform utility to send string messages from Unity to React Native.
/// </summary>
public static class RNMessage
{
#if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void sendMessageToReactNative(string message);
#endif

    /// <summary>
    /// Send a string payload to React Native via platform bridge.
    /// </summary>
    public static void Send(string payload)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            using var jc = new AndroidJavaClass("com.shogo0x2e.uaalforexpoexample.unityview.UnityToReactBridge");
            jc.CallStatic("emitMessage", payload);
        }
        catch (System.Exception ex)
        {
            Debug.unityLogger.LogWarning("RNMessage", $"emitMessage failed (Android): {ex.Message}");
        }
#elif UNITY_IOS && !UNITY_EDITOR
        try
        {
            sendMessageToReactNative(payload);
        }
        catch (System.Exception ex)
        {
            Debug.unityLogger.LogWarning("RNMessage", $"sendMessageToReactNative failed (iOS): {ex.Message}");
        }
#else
        Debug.Log($"[RNMessage] (stub) payload={payload}");
#endif
    }

    /// <summary>
    /// Helper to format float seconds consistently.
    /// </summary>
    public static string FormatSeconds(float seconds)
    {
        return seconds.ToString("0.00\u00A0s", CultureInfo.InvariantCulture);
    }
}
