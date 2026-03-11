using UnityEngine;
using System.Collections;

namespace WeaponSystem
{
    public class CraftingStation : MonoBehaviour
    {
        [Header("Interaction Settings")]
        public KeyCode interactKey = KeyCode.E;
        public float interactionRange = 2f;
        
        [Header("UI References")]
        public GameObject craftingUIPrefab;
        private GameObject currentCraftingUI;
        private bool isUIOpen = false;
        
        [Header("Visual Feedback")]
        public GameObject highlightEffect;
        public string playerTag = "Player";
        
        private GameObject currentPlayer;
        private bool isPlayerNear = false;
        
        void Update()
        {
            // Check for interaction input
            if (Input.GetKeyDown(interactKey) && isPlayerNear && currentPlayer != null)
            {
                if (!isUIOpen)
                {
                    OpenCraftingUI();
                }
                else
                {
                    CloseCraftingUI();
                }
            }
            
            // Close UI if player moves away
            if (isUIOpen && !isPlayerNear)
            {
                CloseCraftingUI();
            }
            
            // Update highlight
            UpdateHighlight();
        }
        
        void OpenCraftingUI()
        {
            if (craftingUIPrefab == null)
            {
                Debug.LogWarning("Crafting UI prefab not assigned!");
                return;
            }
            
            // Create UI instance if not exists
            if (currentCraftingUI == null)
            {
                currentCraftingUI = Instantiate(craftingUIPrefab);
                // Find CraftingUI component and initialize
                CraftingUI craftingUI = currentCraftingUI.GetComponent<CraftingUI>();
                if (craftingUI != null)
                {
                    craftingUI.Initialize(this);
                }
            }
            
            // Show UI
            currentCraftingUI.SetActive(true);
            isUIOpen = true;
            
            // Pause game or disable player input (optional)
            Time.timeScale = 0f;
            
            Debug.Log("Crafting UI opened");
        }
        
        void CloseCraftingUI()
        {
            if (currentCraftingUI != null)
            {
                currentCraftingUI.SetActive(false);
            }
            
            isUIOpen = false;
            
            // Resume game
            Time.timeScale = 1f;
            
            Debug.Log("Crafting UI closed");
        }
        
        void UpdateHighlight()
        {
            if (highlightEffect != null)
            {
                highlightEffect.SetActive(isPlayerNear);
                if (isPlayerNear)
                {
                    highlightEffect.transform.position = transform.position;
                }
            }
        }
        
        void OnTriggerEnter2D(Collider2D other)
        {
            if (other.CompareTag(playerTag))
            {
                isPlayerNear = true;
                currentPlayer = other.gameObject;
                Debug.Log("Player near crafting station. Press " + interactKey + " to open crafting menu.");
            }
        }
        
        void OnTriggerExit2D(Collider2D other)
        {
            if (other.CompareTag(playerTag))
            {
                isPlayerNear = false;
                currentPlayer = null;
                Debug.Log("Player left crafting station area.");
            }
        }
        
        // Called when crafting is successful
        public void OnCraftingComplete(string weaponId)
        {
            Debug.Log($"Crafting complete: {weaponId}");
            CloseCraftingUI();
        }
        
        void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, interactionRange);
        }
        
        void OnDestroy()
        {
            // Clean up UI
            if (currentCraftingUI != null)
            {
                Destroy(currentCraftingUI);
            }
        }
    }
}