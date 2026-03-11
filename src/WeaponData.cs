using UnityEngine;
using System;

namespace WeaponSystem
{
    public enum WeaponType
    {
        Melee,
        Ranged
    }

    public enum WeaponEffect
    {
        None,
        Knockback,
        Bleeding,
        Slow,
        AreaDamage,
        Pierce
    }

    [Serializable]
    public class WeaponData
    {
        public string weaponId;
        public string displayName;
        public WeaponType weaponType;
        public int damage = 5;
        public float attackSpeed = 1.0f;
        public float range = 1.0f;
        public WeaponEffect[] effects;
        public Sprite weaponSprite;
        public GameObject projectilePrefab; // For ranged weapons
        public AudioClip attackSound;
        
        // For UI display
        public string GetEffectDescription()
        {
            if (effects == null || effects.Length == 0)
                return "无特效";
                
            string[] descs = new string[effects.Length];
            for (int i = 0; i < effects.Length; i++)
            {
                descs[i] = effects[i] switch
                {
                    WeaponEffect.Knockback => "击退",
                    WeaponEffect.Bleeding => "流血",
                    WeaponEffect.Slow => "减速",
                    WeaponEffect.AreaDamage => "范围伤害",
                    WeaponEffect.Pierce => "穿透",
                    _ => ""
                };
            }
            return string.Join("、", descs);
        }
        
        public float GetAttackCooldown()
        {
            return 1.0f / attackSpeed;
        }
    }

    [Serializable]
    public class WeaponRecipe
    {
        public string weaponId;
        public ResourceRequirement[] requirements;
        
        [Serializable]
        public class ResourceRequirement
        {
            public ResourceType resourceType;
            public int amount;
        }
    }
}