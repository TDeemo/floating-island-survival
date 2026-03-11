using UnityEngine;
using System.Collections.Generic;

namespace WeaponSystem
{
    public class PlayerWeaponController : MonoBehaviour
    {
        [Header("Weapon Slots")]
        public List<Weapon> equippedWeapons = new List<Weapon>();
        public int currentWeaponIndex = 0;
        
        [Header("Attack Settings")]
        public KeyCode attackKey = KeyCode.Mouse0; // Left mouse button
        public KeyCode altAttackKey = KeyCode.Space; // Spacebar
        public float attackRange = 10f;
        
        [Header("Weapon Switching")]
        public KeyCode[] weaponSwitchKeys = { KeyCode.Alpha1, KeyCode.Alpha2, KeyCode.Alpha3, KeyCode.Alpha4 };
        public bool useMouseWheel = true;
        public float mouseWheelSensitivity = 0.1f;
        
        [Header("Components")]
        public Transform weaponHolder; // Where weapons are attached when equipped
        private Camera mainCamera;
        
        void Start()
        {
            mainCamera = Camera.main;
            
            // Auto-find weapon holder if not assigned
            if (weaponHolder == null)
            {
                weaponHolder = transform.Find("WeaponHolder");
                if (weaponHolder == null)
                {
                    weaponHolder = new GameObject("WeaponHolder").transform;
                    weaponHolder.SetParent(transform);
                    weaponHolder.localPosition = Vector3.zero;
                }
            }
            
            // Initialize with first weapon if any
            if (equippedWeapons.Count > 0)
            {
                SwitchWeapon(0);
            }
            
            Debug.Log("PlayerWeaponController initialized");
        }
        
        void Update()
        {
            // Handle weapon switching
            HandleWeaponSwitching();
            
            // Handle attack input
            HandleAttackInput();
        }
        
        void HandleWeaponSwitching()
        {
            // Check number keys
            for (int i = 0; i < weaponSwitchKeys.Length; i++)
            {
                if (Input.GetKeyDown(weaponSwitchKeys[i]) && i < equippedWeapons.Count)
                {
                    SwitchWeapon(i);
                    break;
                }
            }
            
            // Check mouse wheel
            if (useMouseWheel && equippedWeapons.Count > 1)
            {
                float wheelInput = Input.GetAxis("Mouse ScrollWheel");
                if (Mathf.Abs(wheelInput) > mouseWheelSensitivity)
                {
                    int direction = wheelInput > 0 ? -1 : 1;
                    int newIndex = (currentWeaponIndex + direction + equippedWeapons.Count) % equippedWeapons.Count;
                    SwitchWeapon(newIndex);
                }
            }
        }
        
        void HandleAttackInput()
        {
            if (equippedWeapons.Count == 0) return;
            
            Weapon currentWeapon = equippedWeapons[currentWeaponIndex];
            if (currentWeapon == null) return;
            
            // Primary attack (mouse click)
            if (Input.GetKeyDown(attackKey) || Input.GetKeyDown(altAttackKey))
            {
                // Calculate attack direction
                Vector2 attackDirection = GetAttackDirection();
                
                // Perform attack
                currentWeapon.Attack(attackDirection);
                
                // Visual feedback
                Debug.Log($"Player attacked with {currentWeapon.data.displayName} direction: {attackDirection}");
            }
        }
        
        Vector2 GetAttackDirection()
        {
            // For now, use mouse position relative to player
            if (mainCamera != null)
            {
                Vector3 mouseWorldPos = mainCamera.ScreenToWorldPoint(Input.mousePosition);
                mouseWorldPos.z = transform.position.z;
                Vector2 direction = (mouseWorldPos - transform.position).normalized;
                
                // If direction is zero (mouse on player), default to right
                if (direction.sqrMagnitude < 0.01f)
                {
                    direction = Vector2.right;
                }
                
                return direction;
            }
            
            // Fallback: use player's facing direction
            return transform.localScale.x > 0 ? Vector2.right : Vector2.left;
        }
        
        public void SwitchWeapon(int newIndex)
        {
            if (equippedWeapons.Count == 0) return;
            if (newIndex < 0 || newIndex >= equippedWeapons.Count) return;
            
            // Unequip current weapon
            if (currentWeaponIndex >= 0 && currentWeaponIndex < equippedWeapons.Count)
            {
                Weapon currentWeapon = equippedWeapons[currentWeaponIndex];
                if (currentWeapon != null)
                {
                    currentWeapon.Unequip();
                }
            }
            
            // Equip new weapon
            currentWeaponIndex = newIndex;
            Weapon newWeapon = equippedWeapons[currentWeaponIndex];
            if (newWeapon != null)
            {
                newWeapon.Equip(weaponHolder);
            }
            
            Debug.Log($"Switched to weapon index {currentWeaponIndex}: {newWeapon?.data.displayName}");
        }
        
        public void AddWeapon(Weapon weapon)
        {
            if (weapon == null) return;
            
            // Check if already have this weapon type
            Weapon existing = equippedWeapons.Find(w => w != null && w.data.weaponId == weapon.data.weaponId);
            if (existing != null)
            {
                Debug.Log($"Already have weapon: {weapon.data.displayName}");
                return;
            }
            
            // Add to equipped weapons
            equippedWeapons.Add(weapon);
            
            // If this is the first weapon, equip it
            if (equippedWeapons.Count == 1)
            {
                SwitchWeapon(0);
            }
            
            Debug.Log($"Added weapon: {weapon.data.displayName}. Total weapons: {equippedWeapons.Count}");
        }
        
        public void RemoveWeapon(Weapon weapon)
        {
            if (weapon == null) return;
            
            int index = equippedWeapons.IndexOf(weapon);
            if (index >= 0)
            {
                // If removing current weapon, switch to next available
                if (index == currentWeaponIndex)
                {
                    equippedWeapons.RemoveAt(index);
                    
                    // Try to switch to previous weapon, or next if at beginning
                    if (equippedWeapons.Count > 0)
                    {
                        int newIndex = Mathf.Clamp(index - 1, 0, equippedWeapons.Count - 1);
                        SwitchWeapon(newIndex);
                    }
                    else
                    {
                        currentWeaponIndex = -1;
                    }
                }
                else
                {
                    equippedWeapons.RemoveAt(index);
                    // Adjust currentWeaponIndex if needed
                    if (index < currentWeaponIndex)
                    {
                        currentWeaponIndex--;
                    }
                }
                
                Debug.Log($"Removed weapon: {weapon.data.displayName}");
            }
        }
        
        // Auto-equip weapons when player picks them up
        void OnTriggerEnter2D(Collider2D other)
        {
            // Check if colliding with a weapon pickup
            Weapon weapon = other.GetComponent<Weapon>();
            if (weapon != null && !weapon.isEquipped)
            {
                // Pick up the weapon
                AddWeapon(weapon);
                
                // Disable pickup collider
                Collider2D pickupCollider = weapon.GetComponent<Collider2D>();
                if (pickupCollider != null)
                {
                    pickupCollider.enabled = false;
                }
            }
        }
        
        // For debugging
        void OnDrawGizmosSelected()
        {
            if (equippedWeapons.Count > 0 && currentWeaponIndex < equippedWeapons.Count)
            {
                Weapon currentWeapon = equippedWeapons[currentWeaponIndex];
                if (currentWeapon != null && currentWeapon.data != null)
                {
                    Gizmos.color = Color.red;
                    Gizmos.DrawWireSphere(transform.position, currentWeapon.data.range);
                }
            }
        }
    }
}