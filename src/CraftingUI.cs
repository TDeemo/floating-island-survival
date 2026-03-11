using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using System.Linq;

namespace WeaponSystem
{
    public class CraftingUI : MonoBehaviour
    {
        [Header("UI Components")]
        public GameObject craftingPanel;
        public Transform recipeListContent;
        public GameObject recipeItemPrefab;
        public Text resourceInfoText;
        public Button closeButton;
        
        [Header("Display Settings")]
        public Color craftableColor = Color.green;
        public Color uncraftableColor = Color.gray;
        
        private CraftingStation currentStation;
        private List<RecipeUIItem> recipeItems = new List<RecipeUIItem>();
        
        public void Initialize(CraftingStation station)
        {
            currentStation = station;
            
            // Setup close button
            if (closeButton != null)
            {
                closeButton.onClick.RemoveAllListeners();
                closeButton.onClick.AddListener(CloseUI);
            }
            
            // Populate recipe list
            RefreshRecipeList();
            
            // Update resource info
            UpdateResourceInfo();
        }
        
        void RefreshRecipeList()
        {
            // Clear existing items
            foreach (RecipeUIItem item in recipeItems)
            {
                if (item != null && item.gameObject != null)
                {
                    Destroy(item.gameObject);
                }
            }
            recipeItems.Clear();
            
            if (CraftingManager.Instance == null)
            {
                Debug.LogError("CraftingManager instance not found!");
                return;
            }
            
            // Get all recipes
            List<CraftingManager.CraftingRecipe> recipes = CraftingManager.Instance.GetAvailableRecipes();
            
            // Create UI items
            foreach (var recipe in recipes)
            {
                GameObject itemObj = Instantiate(recipeItemPrefab, recipeListContent);
                RecipeUIItem item = itemObj.GetComponent<RecipeUIItem>();
                
                if (item != null)
                {
                    bool craftable = CraftingManager.Instance.CanCraft(recipe.weaponId);
                    item.Initialize(recipe, craftable, craftableColor, uncraftableColor);
                    
                    // Setup craft button
                    Button craftButton = item.craftButton;
                    if (craftButton != null)
                    {
                        craftButton.onClick.RemoveAllListeners();
                        craftButton.onClick.AddListener(() => OnCraftButtonClicked(recipe.weaponId));
                        
                        // Disable button if not craftable
                        craftButton.interactable = craftable;
                    }
                    
                    recipeItems.Add(item);
                }
            }
            
            Debug.Log($"Populated {recipeItems.Count} recipes in crafting UI");
        }
        
        void OnCraftButtonClicked(string weaponId)
        {
            if (currentStation == null)
            {
                Debug.LogWarning("No crafting station reference!");
                return;
            }
            
            // Craft weapon at station position
            bool success = CraftingManager.Instance.CraftWeapon(weaponId, currentStation.transform.position);
            
            if (success)
            {
                // Notify station
                currentStation.OnCraftingComplete(weaponId);
                
                // Refresh UI
                RefreshRecipeList();
                UpdateResourceInfo();
            }
        }
        
        void UpdateResourceInfo()
        {
            if (GameManager.Instance == null)
            {
                resourceInfoText.text = "GameManager not found";
                return;
            }
            
            string info = $"当前资源:\n";
            info += $"木材: {GameManager.Instance.woodCount}\n";
            info += $"矿石: {GameManager.Instance.stoneCount}\n";
            info += $"药草: {GameManager.Instance.herbCount}";
            
            resourceInfoText.text = info;
        }
        
        void CloseUI()
        {
            if (currentStation != null)
            {
                // Notify station to close UI
                currentStation.SendMessage("CloseCraftingUI");
            }
            else
            {
                // Fallback: just deactivate
                gameObject.SetActive(false);
            }
        }
        
        void Update()
        {
            // Close on Escape key
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                CloseUI();
            }
        }
        
        // Helper class for recipe UI item
        public class RecipeUIItem : MonoBehaviour
        {
            public Text weaponNameText;
            public Text requirementsText;
            public Button craftButton;
            public Image backgroundImage;
            
            public void Initialize(CraftingManager.CraftingRecipe recipe, bool craftable, Color craftableColor, Color uncraftableColor)
            {
                // Set weapon name
                if (weaponNameText != null)
                {
                    string displayName = GetWeaponDisplayName(recipe.weaponId);
                    weaponNameText.text = displayName;
                }
                
                // Set requirements
                if (requirementsText != null)
                {
                    string reqText = "所需材料:\n";
                    foreach (var req in recipe.requirements)
                    {
                        string resourceName = GetResourceDisplayName(req.resourceType);
                        reqText += $"  {resourceName}: {req.amount}\n";
                    }
                    requirementsText.text = reqText;
                }
                
                // Set background color based on craftability
                if (backgroundImage != null)
                {
                    backgroundImage.color = craftable ? craftableColor : uncraftableColor;
                }
            }
            
            private string GetWeaponDisplayName(string weaponId)
            {
                return weaponId switch
                {
                    "sword_wood" => "木剑",
                    "sword_iron" => "铁剑",
                    "bow_wood" => "木弓",
                    "bow_iron" => "铁弓",
                    _ => weaponId
                };
            }
            
            private string GetResourceDisplayName(ResourceType resourceType)
            {
                return resourceType switch
                {
                    ResourceType.Wood => "木材",
                    ResourceType.Ore => "矿石",
                    ResourceType.Berry => "药草",
                    _ => resourceType.ToString()
                };
            }
        }
    }
}