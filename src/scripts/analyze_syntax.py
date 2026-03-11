#!/usr/bin/env python3
import os
import sys
import re

def check_file(filepath):
    """检查单个C#文件的语法问题"""
    issues = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except Exception as e:
        return [f"无法读取文件: {e}"]
    
    # 检查每行的基本语法
    for i, line in enumerate(lines, 1):
        line = line.rstrip('\n')
        
        # 检查未闭合的字符串字面量（奇数个引号）
        if line.count('"') % 2 != 0:
            # 排除注释中的引号？简单检查
            issues.append(f"行{i}: 可能未闭合的字符串字面量")
        
        # 检查未闭合的单引号
        if line.count("'") % 2 != 0:
            issues.append(f"行{i}: 可能未闭合的字符字面量")
        
        # 检查using语句是否以分号结尾
        if line.strip().startswith('using ') and not line.rstrip().endswith(';'):
            # 但可能是多行using，比如using (var x = ...)
            # 只检查简单的using命名空间
            if '=' not in line and '(' not in line:
                issues.append(f"行{i}: using语句可能缺少分号")
    
    # 检查花括号平衡
    content = ''.join(lines)
    open_braces = content.count('{')
    close_braces = content.count('}')
    if open_braces != close_braces:
        issues.append(f"花括号不平衡: 打开{open_braces}个, 关闭{close_braces}个")
    
    return issues

def check_namespace_imports(filepath):
    """检查可能的命名空间引用问题"""
    issues = []
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        return [f"无法读取文件: {e}"]
    
    # 查找using语句
    using_pattern = r'using\s+([\w.]+);'
    using_matches = re.findall(using_pattern, content)
    
    # 常见Unity命名空间
    common_unity_namespaces = [
        'UnityEngine',
        'UnityEngine.UI',
        'UnityEngine.SceneManagement',
        'UnityEngine.Events',
        'System',
        'System.Collections',
        'System.Collections.Generic',
        'System.Linq',
        'System.Text',
        'UnityEditor'
    ]
    
    # 检查是否使用了UnityEngine.Rendering.Universal等
    if 'Universal' in content and 'UnityEngine.Rendering.Universal' not in content:
        # 但可能是通过其他方式引用
        issues.append("可能缺少UnityEngine.Rendering.Universal命名空间")
    
    # 检查常见的类型但未引用对应命名空间
    type_patterns = [
        ('List<', 'System.Collections.Generic'),
        ('Dictionary<', 'System.Collections.Generic'),
        ('GameObject', 'UnityEngine'),
        ('Transform', 'UnityEngine'),
        ('Vector3', 'UnityEngine'),
        ('Debug', 'UnityEngine'),
        ('MonoBehaviour', 'UnityEngine'),
        ('SerializeField', 'UnityEngine'),
        ('SerializeField', 'UnityEngine'),
    ]
    
    for type_name, namespace in type_patterns:
        if type_name in content and namespace not in content:
            # 检查是否已经通过其他命名空间引用（比如UnityEngine包含很多类型）
            if namespace == 'UnityEngine':
                # 如果使用了UnityEngine但可能缺少具体子命名空间
                if 'using UnityEngine;' not in content:
                    issues.append(f"可能缺少UnityEngine命名空间（使用了{type_name}）")
            else:
                issues.append(f"可能缺少{namespace}命名空间（使用了{type_name}）")
    
    return issues

def main():
    # 读取文件列表
    with open('temp/csharp_files.txt', 'r', encoding='utf-8') as f:
        files = [line.strip() for line in f if line.strip()]
    
    print(f"分析 {len(files)} 个文件...")
    
    syntax_issues = []
    namespace_issues = []
    
    # 检查核心系统文件
    core_files = [
        'IslandGenerator.cs',
        'IslandResourcePlacer.cs',
        'TimeManager.cs',
        'ResourceNode.cs',
        'GameManager.cs',
        'PlayerResourceCollector.cs',
        'PlayerHealth.cs',
        'PlayerWeaponController.cs',
        'EnemyHealth.cs',
        'BuildingManager.cs'
    ]
    
    # 优先检查核心文件
    core_file_paths = []
    for file in files:
        for core in core_files:
            if core in file:
                core_file_paths.append(file)
                break
    
    print(f"找到 {len(core_file_paths)} 个核心文件")
    
    # 检查所有文件，但优先记录核心文件的问题
    all_files = core_file_paths + [f for f in files if f not in core_file_paths]
    
    for filepath in all_files:
        # 检查文件是否存在
        if not os.path.exists(filepath):
            continue
            
        # 检查语法问题
        issues = check_file(filepath)
        if issues:
            syntax_issues.append((filepath, issues))
        
        # 检查命名空间问题
        ns_issues = check_namespace_imports(filepath)
        if ns_issues:
            namespace_issues.append((filepath, ns_issues))
    
    # 写入语法问题文件
    with open('temp/syntax_issues.txt', 'a', encoding='utf-8') as f:
        f.write(f"\n# 详细检查结果\n")
        f.write(f"# 共检查文件: {len(all_files)}个\n")
        f.write(f"# 发现语法问题的文件: {len(syntax_issues)}个\n\n")
        
        for filepath, issues in syntax_issues:
            f.write(f"## {filepath}\n")
            for issue in issues:
                f.write(f"- {issue}\n")
            f.write("\n")
    
    # 写入命名空间问题文件
    with open('temp/missing_namespaces.txt', 'w', encoding='utf-8') as f:
        f.write("# 可能的命名空间引用问题\n")
        f.write(f"# 生成时间: 2026-03-07 16:25\n")
        f.write(f"# 检查文件数: {len(all_files)}\n")
        f.write(f"# 发现问题的文件: {len(namespace_issues)}个\n\n")
        
        for filepath, issues in namespace_issues:
            f.write(f"## {filepath}\n")
            for issue in issues:
                f.write(f"- {issue}\n")
            f.write("\n")
    
    print(f"语法问题: {len(syntax_issues)} 个文件")
    print(f"命名空间问题: {len(namespace_issues)} 个文件")
    
    # 生成汇总统计
    total_files = len(all_files)
    files_with_syntax_issues = len(syntax_issues)
    files_with_namespace_issues = len(namespace_issues)
    
    return total_files, files_with_syntax_issues, files_with_namespace_issues

if __name__ == '__main__':
    main()