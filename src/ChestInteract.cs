using UnityEngine;

namespace WeaponSystem
{
    public class ChestInteract : MonoBehaviour
    {
        [Header("Chest Settings")]
        public KeyCode openKey = KeyCode.E;
        public float interactionRange = 1.5f;
        public ChestType chestType = ChestType.Common;
        
        [Header("Visuals")]
        public Sprite closedSprite;
        public Sprite openSprite;
        public GameObject highlightEffect;
        
        [Header("Sounds")]
        public AudioClip openSound;
        
        private SpriteRenderer spriteRenderer;
        private AudioSource audioSource;
        private bool isOpened = false;
        private bool isPlayerNear = false;
        private GameObject currentPlayer;
        
        public enum ChestType
        {
            Common,
            Rare
        }
        
        void Start()
        {
            spriteRenderer = GetComponent<SpriteRenderer>();
            if (spriteRenderer == null)
            {
                spriteRenderer = gameObject.AddComponent<SpriteRenderer>();
            }
            
            // Set initial sprite
            if (closedSprite != null)
            {
                spriteRenderer.sprite = closedSprite;
            }
            
            // Add AudioSource if needed
            audioSource = GetComponent<AudioSource>();
            if (audioSource == null && openSound != null)
            {
                audioSource = gameObject.AddComponent<AudioSource>();
                audioSource.playOnAwake = false;
            }
        }
        
        void Update()
        {
            // Check for open input
            if (Input.GetKeyDown(openKey) && isPlayerNear && !isOpened)
            {
                OpenChest();
            }
            
            // Update highlight
            UpdateHighlight();
        }
        
        void OpenChest()
        {
            if (isOpened) return;
            
            isOpened = true;
            
            // Change sprite
            if (openSprite != null)
            {
                spriteRenderer.sprite = openSprite;
            }
            
            // Play sound
            if (audioSource != null && openSound != null)
            {
                audioSource.PlayOneShot(openSound);
            }
            
            // Trigger weapon drop
            DropWeapon();
            
            Debug.Log($"Opened {chestType} chest at {transform.position}");
        }
        
        void DropWeapon()
        {
            if (WeaponDropSystem.Instance == null)
            {
                Debug.LogWarning("WeaponDropSystem instance not found!");
                return;
            }
            
            // Call appropriate drop method based on chest type
            switch (chestType)
            {
                case ChestType.Common:
                    WeaponDropSystem.Instance.DropFromCommonChest(transform.position);
                    break;
                case ChestType.Rare:
                    WeaponDropSystem.Instance.DropFromRareChest(transform.position);
                    break;
            }
        }
        
        void UpdateHighlight()
        {
            if (highlightEffect != null)
            {
                highlightEffect.SetActive(isPlayerNear && !isOpened);
            }
        }
        
        void OnTriggerEnter2D(Collider2D other)
        {
            if (other.CompareTag("Player"))
            {
                isPlayerNear = true;
                currentPlayer = other.gameObject;
                
                if (!isOpened)
                {
                    Debug.Log($"Player near chest. Press {openKey} to open.");
                }
            }
        }
        
        void OnTriggerExit2D(Collider2D other)
        {
            if (other.CompareTag("Player"))
            {
                isPlayerNear = false;
                currentPlayer = null;
            }
        }
        
        // Reset chest (for testing)
        public void ResetChest()
        {
            isOpened = false;
            if (closedSprite != null)
            {
                spriteRenderer.sprite = closedSprite;
            }
        }
        
        void OnDrawGizmosSelected()
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, interactionRange);
        }
    }
}