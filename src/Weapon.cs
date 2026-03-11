using UnityEngine;
using System.Collections;

namespace WeaponSystem
{
    public class Weapon : MonoBehaviour
    {
        [Header("Weapon Data")]
        public WeaponData data;
        
        [Header("Components")]
        public SpriteRenderer spriteRenderer;
        public Collider2D pickupCollider;
        
        [Header("State")]
        public bool isEquipped = false;
        public Transform currentHolder;
        private float lastAttackTime = 0f;
        
        void Start()
        {
            if (spriteRenderer == null)
                spriteRenderer = GetComponent<SpriteRenderer>();
            
            if (pickupCollider == null)
                pickupCollider = GetComponent<Collider2D>();
            
            // Set sprite if available
            if (data != null && data.weaponSprite != null && spriteRenderer != null)
            {
                spriteRenderer.sprite = data.weaponSprite;
            }
            
            // Initially enable pickup collider
            if (pickupCollider != null)
                pickupCollider.enabled = true;
        }
        
        public void Equip(Transform holder)
        {
            if (isEquipped) return;
            
            currentHolder = holder;
            isEquipped = true;
            
            // Disable pickup collider when equipped
            if (pickupCollider != null)
                pickupCollider.enabled = false;
            
            // Attach to holder (could be a child transform)
            transform.SetParent(holder);
            transform.localPosition = Vector3.zero;
            transform.localRotation = Quaternion.identity;
            
            Debug.Log($"武器装备: {data.displayName}");
        }
        
        public void Unequip()
        {
            if (!isEquipped) return;
            
            isEquipped = false;
            currentHolder = null;
            
            // Enable pickup collider
            if (pickupCollider != null)
                pickupCollider.enabled = true;
            
            // Detach from holder
            transform.SetParent(null);
            
            Debug.Log($"武器卸下: {data.displayName}");
        }
        
        public bool CanAttack()
        {
            if (data == null) return false;
            
            float cooldown = data.GetAttackCooldown();
            return Time.time >= lastAttackTime + cooldown;
        }
        
        public void Attack(Vector2 direction)
        {
            if (!CanAttack()) return;
            
            lastAttackTime = Time.time;
            
            // Play attack sound
            if (data.attackSound != null)
            {
                AudioSource.PlayClipAtPoint(data.attackSound, transform.position);
            }
            
            // Trigger attack based on weapon type
            if (data.weaponType == WeaponType.Melee)
            {
                PerformMeleeAttack(direction);
            }
            else
            {
                PerformRangedAttack(direction);
            }
            
            Debug.Log($"攻击执行: {data.displayName} 方向: {direction}");
        }
        
        private void PerformMeleeAttack(Vector2 direction)
        {
            // Create a melee attack area
            Collider2D[] hits = Physics2D.OverlapCircleAll(
                transform.position + (Vector3)direction * data.range * 0.5f,
                data.range * 0.5f
            );
            
            foreach (Collider2D hit in hits)
            {
                if (hit.CompareTag("Enemy"))
                {
                    // Apply damage
                    EnemyHealth enemyHealth = hit.GetComponent<EnemyHealth>();
                    if (enemyHealth != null)
                    {
                        enemyHealth.TakeDamage(data.damage);
                        ApplyEffects(hit.gameObject);
                    }
                }
                else if (hit.CompareTag("Resource"))
                {
                    // Can also harvest resources with weapons
                    ResourceNode resource = hit.GetComponent<ResourceNode>();
                    if (resource != null)
                    {
                        resource.Harvest();
                    }
                }
            }
            
            // Trigger attack animation (if holder has animator)
            if (currentHolder != null)
            {
                Animator animator = currentHolder.GetComponent<Animator>();
                if (animator != null)
                {
                    animator.SetTrigger("Attack");
                }
            }
        }
        
        private void PerformRangedAttack(Vector2 direction)
        {
            if (data.projectilePrefab == null)
            {
                Debug.LogWarning($"远程武器 {data.displayName} 缺少投射物预制体");
                return;
            }
            
            // Instantiate projectile
            GameObject projectile = Instantiate(
                data.projectilePrefab,
                transform.position,
                Quaternion.identity
            );
            
            // Set projectile direction and damage
            ArrowProjectile arrow = projectile.GetComponent<ArrowProjectile>();
            if (arrow != null)
            {
                arrow.damage = data.damage;
                arrow.Launch(direction);
                
                // Apply effects to projectile
                arrow.effects = data.effects;
            }
            
            // Trigger shoot animation
            if (currentHolder != null)
            {
                Animator animator = currentHolder.GetComponent<Animator>();
                if (animator != null)
                {
                    animator.SetTrigger("Shoot");
                }
            }
        }
        
        private void ApplyEffects(GameObject target)
        {
            if (data.effects == null) return;
            
            foreach (WeaponEffect effect in data.effects)
            {
                switch (effect)
                {
                    case WeaponEffect.Knockback:
                        ApplyKnockback(target);
                        break;
                    case WeaponEffect.Bleeding:
                        ApplyBleeding(target);
                        break;
                    case WeaponEffect.Slow:
                        ApplySlow(target);
                        break;
                    // Other effects can be implemented later
                }
            }
        }
        
        private void ApplyKnockback(GameObject target)
        {
            Rigidbody2D rb = target.GetComponent<Rigidbody2D>();
            if (rb != null)
            {
                Vector2 knockbackDir = (target.transform.position - transform.position).normalized;
                rb.AddForce(knockbackDir * 5f, ForceMode2D.Impulse);
            }
        }
        
        private void ApplyBleeding(GameObject target)
        {
            // Could implement a bleeding DOT component
            Debug.Log($"施加流血效果: {target.name}");
        }
        
        private void ApplySlow(GameObject target)
        {
            // Could implement a slow movement component
            Debug.Log($"施加减速效果: {target.name}");
        }
        
        void OnDrawGizmosSelected()
        {
            if (data == null) return;
            
            // Visualize attack range
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, data.range);
        }
    }
}