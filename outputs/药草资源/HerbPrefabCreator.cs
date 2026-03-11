using UnityEngine;
using UnityEditor;
using System.IO;

public class HerbPrefabCreator : EditorWindow
{
    private string prefabName = "Herb_Node";
    
    [MenuItem("Tools/Resource System/Create Herb Prefab")]
    public static void ShowWindow()
    {
        GetWindow<HerbPrefabCreator>("Herb Prefab Creator");
    }
    
    [MenuItem("Tools/Resource System/Create Herb Prefab (Quick)")]
    public static void CreateHerbPrefab()
    {
        CreatePrefab();
    }
    
    void OnGUI()
    {
        GUILayout.Label("Create Herb Resource Prefab", EditorStyles.boldLabel);
        
        prefabName = EditorGUILayout.TextField("Prefab Name", prefabName);
        
        if (GUILayout.Button("Create Prefab"))
        {
            CreatePrefab(prefabName);
        }
    }
    
    public static void CreatePrefab(string name = "Herb_Node")
    {
        // Ensure directory exists
        string prefabDir = "Assets/Prefabs/Resources";
        if (!Directory.Exists(prefabDir))
        {
            Directory.CreateDirectory(prefabDir);
        }
        
        // Create GameObject
        GameObject go = new GameObject(name);
        
        // Add SpriteRenderer
        SpriteRenderer sr = go.AddComponent<SpriteRenderer>();
        
        // Load herb sprite
        string spritePath = "Assets/Sprites/Resources/Herb_Sprite.png";
        Sprite herbSprite = AssetDatabase.LoadAssetAtPath<Sprite>(spritePath);
        if (herbSprite != null)
        {
            sr.sprite = herbSprite;
            Debug.Log($"Herb sprite loaded: {spritePath}");
        }
        else
        {
            Debug.LogWarning($"Herb sprite not found at {spritePath}. Using default.");
            // Create a default sprite (green square)
            Texture2D texture = new Texture2D(32, 32);
            Color[] colors = new Color[32 * 32];
            for (int i = 0; i < colors.Length; i++)
            {
                colors[i] = Color.green;
            }
            texture.SetPixels(colors);
            texture.Apply();
            sr.sprite = Sprite.Create(texture, 
                new Rect(0, 0, texture.width, texture.height), 
                new Vector2(0.5f, 0.5f));
        }
        
        // Add Collider2D
        BoxCollider2D collider = go.AddComponent<BoxCollider2D>();
        collider.size = new Vector2(0.8f, 0.8f);
        collider.isTrigger = true;
        
        // Add ResourceNode script
        ResourceNode resourceNode = go.AddComponent<ResourceNode>();
        resourceNode.resourceType = ResourceType.Herb;
        resourceNode.maxHealth = 2;
        resourceNode.resourceYield = 1;
        
        // Load sprites for ResourceNode states (use herb sprite for all states for now)
        resourceNode.healthySprite = sr.sprite;
        resourceNode.damagedSprite = sr.sprite;
        resourceNode.depletedSprite = sr.sprite;
        
        // Save as prefab
        string prefabPath = Path.Combine(prefabDir, name + ".prefab");
        PrefabUtility.SaveAsPrefabAsset(go, prefabPath);
        
        // Destroy temporary GameObject
        DestroyImmediate(go);
        
        Debug.Log($"Herb prefab created: {prefabPath}");
        AssetDatabase.Refresh();
        
        // Assign prefab reference to IslandResourcePlacer if possible
        AssignPrefabToPlacer(prefabPath);
    }
    
    static void AssignPrefabToPlacer(string prefabPath)
    {
        // Load the prefab
        GameObject herbPrefab = AssetDatabase.LoadAssetAtPath<GameObject>(prefabPath);
        if (herbPrefab == null)
        {
            Debug.LogWarning($"Could not load herb prefab at {prefabPath}");
            return;
        }
        
        // Find IslandResourcePlacer instance in the scene
        IslandResourcePlacer placer = FindObjectOfType<IslandResourcePlacer>();
        if (placer != null)
        {
            placer.herbPrefab = herbPrefab;
            EditorUtility.SetDirty(placer);
            Debug.Log("Herb prefab assigned to IslandResourcePlacer in scene.");
        }
        else
        {
            Debug.LogWarning("IslandResourcePlacer not found in scene. Please assign herbPrefab manually.");
        }
    }
}