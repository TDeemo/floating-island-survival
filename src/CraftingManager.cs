using UnityEngine;
using System.Collections.Generic;

namespace WeaponSystem
{
    public class CraftingManager : MonoBehaviour
    {
        public static CraftingManager Instance { get; private set; }
        
        [System.Serializable]
        public class CraftingRecipe
        {
            public string weaponId;
            public List<ResourceRequirement> requirements;
            
            [System.Serializable]
            public class ResourceRequirement
            {
                public ResourceType resourceType;
                public int amount;
            }
        }
        
        [Header("Recipes")]
        public List<CraftingRecipe> recipes = new List<CraftingRecipe>();
        
        [Header("Prefabs")]
        public GameObject swordWoodPrefab;
        public GameObject swordIronPrefab;
        public GameObject bowWoodPrefab;
        public GameObject bowIronPrefab;
        
        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
            
            InitializeDefaultRecipes();
        }
        
        void InitializeDefaultRecipes()
        {
            // Clear existing recipes
            recipes.Clear();
            
            // Wood Sword: 3 Wood
            CraftingRecipe woodSwordRecipe = new CraftingRecipe
            {
                weaponId = "sword_wood",
                requirements = new List<CraftingRecipe.ResourceRequirement>
                {
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Wood, amount = 3 }
                }
            };
            recipes.Add(woodSwordRecipe);
            
            // Iron Sword: 2 Wood + 5 Ore
            CraftingRecipe ironSwordRecipe = new CraftingRecipe
            {
                weaponId = "sword_iron",
                requirements = new List<CraftingRecipe.ResourceRequirement>
                {
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Wood, amount = 2 },
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Ore, amount = 5 }
                }
            };
            recipes.Add(ironSwordRecipe);
            
            // Wood Bow: 5 Wood
            CraftingRecipe woodBowRecipe = new CraftingRecipe
            {
                weaponId = "bow_wood",
                requirements = new List<CraftingRecipe.ResourceRequirement>
                {
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Wood, amount = 5 }
                }
            };
            recipes.Add(woodBowRecipe);
            
            // Iron Bow: 3 Wood + 8 Ore
            CraftingRecipe ironBowRecipe = new CraftingRecipe
            {
                weaponId = "bow_iron",
                requirements = new List<CraftingRecipe.ResourceRequirement>
                {
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Wood, amount = 3 },
                    new CraftingRecipe.ResourceRequirement { resourceType = ResourceType.Ore, amount = 8 }
                }
            };
            recipes.Add(ironBowRecipe);
            
            Debug.Log($"Initialized {recipes.Count} crafting recipes");
        }
        
        public bool CanCraft(string weaponId)
        {
            CraftingRecipe recipe = FindRecipe(weaponId);
            if (recipe == null)
            {
                Debug.LogWarning($"Recipe not found for weapon: {weaponId}");
                return false;
            }
            
            // Check if player has enough resources
            if (GameManager.Instance == null)
            {
                Debug.LogError("GameManager instance not found!");
                return false;
            }
            
            foreach (var requirement in recipe.requirements)
            {
                int playerResourceCount = GetPlayerResourceCount(requirement.resourceType);
                if (playerResourceCount < requirement.amount)
                {
                    return false;
                }
            }
            
            return true;
        }
        
        public bool CraftWeapon(string weaponId, Vector3 spawnPosition)
        {
            if (!CanCraft(weaponId))
            {
                Debug.LogWarning($"Cannot craft weapon {weaponId}: insufficient resources or recipe not found");
                return false;
            }
            
            CraftingRecipe recipe = FindRecipe(weaponId);
            if (recipe == null) return false;
            
            // Deduct resources
            foreach (var requirement in recipe.requirements)
            {
                DeductResource(requirement.resourceType, requirement.amount);
            }
            
            // Spawn weapon
            GameObject weaponPrefab = GetWeaponPrefab(weaponId);
            if (weaponPrefab == null)
            {
                Debug.LogWarning($"No prefab found for weapon: {weaponId}");
                return false;
            }
            
            GameObject weaponInstance = Instantiate(weaponPrefab, spawnPosition, Quaternion.identity);
            Debug.Log($"Crafted weapon: {weaponId} at {spawnPosition}");
            
            // Add to player inventory (future extension)
            // PlayerInventory.Instance.AddWeapon(weaponInstance);
            
            return true;
        }
        
        private CraftingRecipe FindRecipe(string weaponId)
        {
            return recipes.Find(r => r.weaponId == weaponId);
        }
        
        private int GetPlayerResourceCount(ResourceType resourceType)
        {
            if (GameManager.Instance == null) return 0;
            
            switch (resourceType)
            {
                case ResourceType.Wood:
                    return GameManager.Instance.woodCount;
                case ResourceType.Ore:
                    return GameManager.Instance.stoneCount; // GameManager uses "stone" for ore
                case ResourceType.Berry:
                    return GameManager.Instance.herbCount; // GameManager uses "herb" for berry
                default:
                    return 0;
            }
        }
        
        private void DeductResource(ResourceType resourceType, int amount)
        {
            if (GameManager.Instance == null) return;
            
            switch (resourceType)
            {
                case ResourceType.Wood:
                    GameManager.Instance.woodCount = Mathf.Max(0, GameManager.Instance.woodCount - amount);
                    break;
                case ResourceType.Ore:
                    GameManager.Instance.stoneCount = Mathf.Max(0, GameManager.Instance.stoneCount - amount);
                    break;
                case ResourceType.Berry:
                    GameManager.Instance.herbCount = Mathf.Max(0, GameManager.Instance.herbCount - amount);
                    break;
            }
            
            Debug.Log($"Deducted {amount} {resourceType}. Current resources: Wood={GameManager.Instance.woodCount}, Stone={GameManager.Instance.stoneCount}, Herb={GameManager.Instance.herbCount}");
        }
        
        private GameObject GetWeaponPrefab(string weaponId)
        {
            switch (weaponId)
            {
                case "sword_wood":
                    return swordWoodPrefab;
                case "sword_iron":
                    return swordIronPrefab;
                case "bow_wood":
                    return bowWoodPrefab;
                case "bow_iron":
                    return bowIronPrefab;
                default:
                    return null;
            }
        }
        
        public List<CraftingRecipe> GetAvailableRecipes()
        {
            return recipes;
        }
        
        public List<CraftingRecipe> GetCraftableRecipes()
        {
            List<CraftingRecipe> craftable = new List<CraftingRecipe>();
            foreach (var recipe in recipes)
            {
                if (CanCraft(recipe.weaponId))
                {
                    craftable.Add(recipe);
                }
            }
            return craftable;
        }
    }
}