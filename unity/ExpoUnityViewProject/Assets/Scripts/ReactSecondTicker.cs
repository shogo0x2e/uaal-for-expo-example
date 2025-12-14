using System.Collections;
using System.Globalization;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Displays elapsed time on a legacy Text and sends the value to React Native every interval.
/// Intended for driving Android → RN messaging verification.
/// </summary>
public class ReactSecondTicker : MonoBehaviour
{
    [SerializeField] private Text targetText;
    [SerializeField] private float intervalSeconds = 0.01f;

    private float startTime;
    private WaitForSeconds waitInterval;

    private void Awake()
    {
        if (intervalSeconds <= 0f)
        {
            intervalSeconds = 0.01f;
        }

        waitInterval = new WaitForSeconds(intervalSeconds);
        startTime = Time.realtimeSinceStartup;
    }

    private void OnEnable()
    {
        StartCoroutine(TickLoop());
    }

    private void OnDisable()
    {
        StopAllCoroutines();
    }

    private IEnumerator TickLoop()
    {
        while (true)
        {
            var elapsed = Time.realtimeSinceStartup - startTime;

            if (targetText != null)
            {
                targetText.text = RNMessage.FormatSeconds(elapsed);
            }

            SendToReact(elapsed);

            yield return waitInterval;
        }
    }

    private void SendToReact(float seconds)
    {
        var payload = RNMessage.FormatSeconds(seconds);
        RNMessage.Send(payload);
    }

    private void Reset()
    {
        targetText = GetComponentInChildren<Text>();
    }
}
