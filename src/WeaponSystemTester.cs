using UnityEngine;
using System.Collections;

namespace WeaponSystem
{
    public class WeaponSystemTester : MonoBehaviour
    {
        [Header("Test Settings")]
        public bool runAutomatedTests = true;
        public float testDelay = 1f;
        
        [Header("References")]
        public CraftingManager craftingManager;
        public WeaponDropSystem weaponDropSystem;
        public PlayerWeaponController playerWeaponController;
        public GameObject testChest;
        public GameObject testEnemy;
        
        private int testStep = 0;
        private float nextTestTime = 0f;
        
        void Start()
        {
            if (runAutomatedTests)
            {
                nextTestTime = Time.time + testDelay;
                Debug.Log("Weapon system automated tests starting in " + testDelay + " seconds...");
            }
        }
        
        void Update()
        {
            if (runAutomatedTests && Time.time >= nextTestTime)
            {
                RunNextTest();
                nextTestTime = Time.time + testDelay;
            }
            
            // Manual test controls
            if (Input.GetKeyDown(KeyCode.T))
            {
                RunAllTests();
            }
        }
        
        void RunNextTest()
        {
            switch (testStep)
            {
                case 0:
                    TestCraftingManagerExists();
                    break;
                case 1:
                    TestWeaponDropSystemExists();
                    break;
                case 2:
                    TestPlayerWeaponControllerExists();
                    break;
                case 3:
                    TestCraftingRecipes();
                    break;
                case 4:
                    TestWeaponDropMethods();
                    break;
                case 5:
                    TestManualCrafting();
                    break;
                default:
                    Debug.Log("All tests completed!");
                    runAutomatedTests = false;
                    break;
            }
            testStep++;
        }
        
        void RunAllTests()
        {
            Debug.Log("=== Running All Weapon System Tests ===");
            
            TestCraftingManagerExists();
            TestWeaponDropSystemExists();
            TestPlayerWeaponControllerExists();
            TestCraftingRecipes();
            TestWeaponDropMethods();
            
            Debug.Log("=== All Tests Completed ===");
        }
        
        void TestCraftingManagerExists()
        {
            if (craftingManager != null)
            {
                Debug.Log("✓ CraftingManager found");
                
                // Test recipe count
                int recipeCount = craftingManager.GetAvailableRecipes().Count;
                Debug.Log($"  Recipes available: {recipeCount}");
                
                if (recipeCount >= 2)
                {
                    Debug.Log("✓ At least 2 recipes available (minimum requirement)");
                }
                else
                {
                    Debug.LogWarning("✗ Less than 2 recipes available");
                }
            }
            else
            {
                Debug.LogError("✗ CraftingManager not found or not assigned");
            }
        }
        
        void TestWeaponDropSystemExists()
        {
            if (weaponDropSystem != null)
            {
                Debug.Log("✓ WeaponDropSystem found");
                
                // Test if drop tables are initialized
                if (weaponDropSystem.normalEnemyTable != null &&
                    weaponDropSystem.commonChestTable != null)
                {
                    Debug.Log("✓ Drop tables initialized");
                }
                else
                {
                    Debug.LogWarning("✗ Some drop tables not initialized");
                }
            }
            else
            {
                Debug.LogError("✗ WeaponDropSystem not found or not assigned");
            }
        }
        
        void TestPlayerWeaponControllerExists()
        {
            if (playerWeaponController != null)
            {
                Debug.Log("✓ PlayerWeaponController found");
                
                // Test weapon holder
                if (playerWeaponController.weaponHolder != null)
                {
                    Debug.Log("✓ Weapon holder assigned");
                }
                else
                {
                    Debug.LogWarning("✗ Weapon holder not assigned");
                }
            }
            else
            {
                Debug.LogError("✗ PlayerWeaponController not found or not assigned");
            }
        }
        
        void TestCraftingRecipes()
        {
            if (craftingManager == null) return;
            
            Debug.Log("Testing crafting recipes...");
            
            // Test specific recipes
            string[] testWeapons = { "sword_wood", "bow_wood" };
            
            foreach (string weaponId in testWeapons)
            {
                bool canCraft = craftingManager.CanCraft(weaponId);
                Debug.Log($"  {weaponId}: {(canCraft ? "Craftable" : "Not craftable")}");
            }
            
            // Check craftable recipes list
            var craftable = craftingManager.GetCraftableRecipes();
            Debug.Log($"Craftable recipes: {craftable.Count}");
        }
        
        void TestWeaponDropMethods()
        {
            if (weaponDropSystem == null) return;
            
            Debug.Log("Testing weapon drop methods (simulation)...");
            
            // Simulate drops at origin
            Vector3 testPosition = Vector3.zero;
            
            // Test each drop method exists
            System.Reflection.MethodInfo[] methods = weaponDropSystem.GetType().GetMethods();
            string[] requiredMethods = { "DropFromNormalEnemy", "DropFromCommonChest" };
            
            foreach (string methodName in requiredMethods)
            {
                bool methodExists = System.Array.Exists(methods, m => m.Name == methodName);
                Debug.Log($"  {methodName}: {(methodExists ? "Exists" : "Missing")}");
            }
        }
        
        void TestManualCrafting()
        {
            if (craftingManager == null) return;
            
            Debug.Log("Manual crafting test (simulated)...");
            
            // Simulate having resources
            if (GameManager.Instance != null)
            {
                GameManager.Instance.woodCount = 10;
                GameManager.Instance.stoneCount = 10;
                GameManager.Instance.herbCount = 10;
                
                Debug.Log("Resources set to 10 each for testing");
                
                // Try to craft wood sword
                bool success = craftingManager.CraftWeapon("sword_wood", transform.position);
                Debug.Log($"Craft sword_wood: {(success ? "Success" : "Failed")}");
            }
        }
        
        // Public method for manual testing
        public void TestCraftWeapon(string weaponId)
        {
            if (craftingManager != null)
            {
                bool success = craftingManager.CraftWeapon(weaponId, transform.position);
                Debug.Log($"Test craft {weaponId}: {(success ? "Success" : "Failed")}");
            }
        }
        
        public void TestDropFromNormalEnemy()
        {
            if (weaponDropSystem != null)
            {
                weaponDropSystem.DropFromNormalEnemy(transform.position);
                Debug.Log("Test normal enemy drop triggered");
            }
        }
        
        public void TestDropFromCommonChest()
        {
            if (weaponDropSystem != null)
            {
                weaponDropSystem.DropFromCommonChest(transform.position);
                Debug.Log("Test common chest drop triggered");
            }
        }
        
        void OnGUI()
        {
            if (!runAutomatedTests)
            {
                GUILayout.BeginArea(new Rect(10, 10, 300, 200));
                GUILayout.Label("Weapon System Tester");
                
                if (GUILayout.Button("Test Crafting Manager"))
                {
                    TestCraftingManagerExists();
                }
                
                if (GUILayout.Button("Test Recipes"))
                {
                    TestCraftingRecipes();
                }
                
                if (craftingManager != null)
                {
                    if (GUILayout.Button("Craft Wood Sword"))
                    {
                        TestCraftWeapon("sword_wood");
                    }
                    
                    if (GUILayout.Button("Craft Wood Bow"))
                    {
                        TestCraftWeapon("bow_wood");
                    }
                }
                
                if (weaponDropSystem != null)
                {
                    if (GUILayout.Button("Test Enemy Drop"))
                    {
                        TestDropFromNormalEnemy();
                    }
                    
                    if (GUILayout.Button("Test Chest Drop"))
                    {
                        TestDropFromCommonChest();
                    }
                }
                
                GUILayout.EndArea();
            }
        }
    }
}