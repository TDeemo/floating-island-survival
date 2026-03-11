using UnityEngine;
using System.Collections.Generic;

namespace WeaponSystem
{
    public class WeaponDropSystem : MonoBehaviour
    {
        public static WeaponDropSystem Instance { get; private set; }
        
        [System.Serializable]
        public class DropItem
        {
            public string weaponId;
            public float weight = 1f;
            public GameObject weaponPrefab;
        }
        
        [System.Serializable]
        public class DropTable
        {
            public string tableId;
            public float dropChance = 0.1f; // 10% chance to drop anything
            public DropItem[] items;
        }
        
        [Header("Drop Tables")]
        public DropTable normalEnemyTable;
        public DropTable eliteEnemyTable;
        public DropTable bossEnemyTable;
        public DropTable commonChestTable;
        public DropTable rareChestTable;
        
        [Header("Settings")]
        public float dropSpawnRadius = 1f;
        
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
        }
        
        void Start()
        {
            InitializeDefaultTables();
        }
        
        private void InitializeDefaultTables()
        {
            // Normal enemy table: 10% chance, wood weapons
            normalEnemyTable = new DropTable
            {
                tableId = "normal_enemy",
                dropChance = 0.1f,
                items = new DropItem[]
                {
                    new DropItem { weaponId = "sword_wood", weight = 1f },
                    new DropItem { weaponId = "bow_wood", weight = 1f }
                }
            };
            
            // Elite enemy table: 25% chance, iron weapons
            eliteEnemyTable = new DropTable
            {
                tableId = "elite_enemy",
                dropChance = 0.25f,
                items = new DropItem[]
                {
                    new DropItem { weaponId = "sword_iron", weight = 1f },
                    new DropItem { weaponId = "bow_iron", weight = 1f }
                }
            };
            
            // Common chest table: 30% chance, wood weapons
            commonChestTable = new DropTable
            {
                tableId = "common_chest",
                dropChance = 0.3f,
                items = new DropItem[]
                {
                    new DropItem { weaponId = "sword_wood", weight = 0.6f },
                    new DropItem { weaponId = "bow_wood", weight = 0.4f }
                }
            };
            
            // Rare chest table: 70% chance, iron weapons
            rareChestTable = new DropTable
            {
                tableId = "rare_chest",
                dropChance = 0.7f,
                items = new DropItem[]
                {
                    new DropItem { weaponId = "sword_iron", weight = 0.5f },
                    new DropItem { weaponId = "bow_iron", weight = 0.5f }
                }
            };
        }
        
        public GameObject GetWeaponPrefab(string weaponId)
        {
            // This would normally load from Resources or AssetDatabase
            // For now, return null and we'll handle prefab assignment in editor
            return null;
        }
        
        public void TryDropFromTable(Vector3 position, DropTable table)
        {
            if (table == null) return;
            
            // Check if something drops
            if (Random.value > table.dropChance) return;
            
            // Select item based on weights
            DropItem selectedItem = SelectWeightedItem(table.items);
            if (selectedItem == null) return;
            
            // Get prefab (in real implementation, load from Resources)
            GameObject weaponPrefab = GetWeaponPrefab(selectedItem.weaponId);
            if (weaponPrefab == null)
            {
                Debug.LogWarning($"无法找到武器预制体: {selectedItem.weaponId}");
                return;
            }
            
            // Spawn weapon
            Vector3 spawnPos = position + new Vector3(
                Random.Range(-dropSpawnRadius, dropSpawnRadius),
                Random.Range(-dropSpawnRadius, dropSpawnRadius),
                0
            );
            
            Instantiate(weaponPrefab, spawnPos, Quaternion.identity);
            Debug.Log($"掉落武器: {selectedItem.weaponId} 位置: {spawnPos}");
        }
        
        private DropItem SelectWeightedItem(DropItem[] items)
        {
            if (items == null || items.Length == 0) return null;
            
            float totalWeight = 0f;
            foreach (DropItem item in items)
            {
                totalWeight += item.weight;
            }
            
            float randomValue = Random.Range(0f, totalWeight);
            float currentWeight = 0f;
            
            foreach (DropItem item in items)
            {
                currentWeight += item.weight;
                if (randomValue <= currentWeight)
                {
                    return item;
                }
            }
            
            return items[items.Length - 1];
        }
        
        // Public methods for other systems to call
        public void DropFromNormalEnemy(Vector3 position)
        {
            TryDropFromTable(position, normalEnemyTable);
        }
        
        public void DropFromEliteEnemy(Vector3 position)
        {
            TryDropFromTable(position, eliteEnemyTable);
        }
        
        public void DropFromCommonChest(Vector3 position)
        {
            TryDropFromTable(position, commonChestTable);
        }
        
        public void DropFromRareChest(Vector3 position)
        {
            TryDropFromTable(position, rareChestTable);
        }
    }
}