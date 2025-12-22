using UnityEngine;

public class ColorController : MonoBehaviour
{
    [SerializeField]
    private GameObject targetObject;

    public void ChangeColor(string colorName)
    {
        Color newColor;

        switch (colorName.ToLower())
        {
            case "red":
                newColor = Color.red;
                break;
            case "green":
                newColor = Color.green;
                break;
            case "blue":
                newColor = Color.blue;
                break;
            case "yellow":
                newColor = Color.yellow;
                break;
            case "black":
                newColor = Color.black;
                break;
            case "white":
                newColor = Color.white;
                break;
            default:
                Debug.LogWarning("Color not recognized. Defaulting to white.");
                newColor = Color.white;
                break;
        }

        Renderer renderer = targetObject.GetComponent<Renderer>();
        if (renderer != null)
        {
            renderer.material.color = newColor;
        }
        else
        {
            Debug.LogError("Target object does not have a Renderer component.");
        }
    }
}
