#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
脚本：build-offline.py
说明：将 HBuilderX CLI 导出的最新离线应用资源（www）注入官方匹配基座 APK，
     同步修改 AndroidManifest.xml 的 versionName 和 versionCode，
     并自动调用 Android SDK 工具完成 4 字节边界对齐和 V2/V3 私钥重新签名。
"""

import os
import sys
import shutil
import zipfile
import argparse
import subprocess
import glob

def find_android_tool(tool_name):
    """在系统 PATH 或 ANDROID_HOME / ANDROID_SDK_ROOT 中寻找 Android SDK 构建工具"""
    p = shutil.which(tool_name)
    if p:
        return p
    if sys.platform.startswith('win'):
        p = shutil.which(f"{tool_name}.bat")
        if p:
            return p

    sdk_root = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if sdk_root:
        pattern = os.path.join(sdk_root, 'build-tools', '*', tool_name + ('.bat' if sys.platform.startswith('win') else ''))
        matches = glob.glob(pattern)
        if matches:
            matches.sort(reverse=True)
            return matches[0]
        pattern2 = os.path.join(sdk_root, 'build-tools', '*', tool_name)
        matches2 = glob.glob(pattern2)
        if matches2:
            matches2.sort(reverse=True)
            return matches2[0]

    return None

def update_manifest_version(manifest_bytes, version_name, version_code):
    """通过 pyaxml 更新 AndroidManifest.xml 的 versionName 和 versionCode"""
    try:
        import pyaxml
        axml = pyaxml.AXML.from_axml(manifest_bytes)
        root = axml.to_xml()
        android_ns = '{http://schemas.android.com/apk/res/android}'

        old_code = root.attrib.get(f'{android_ns}versionCode')
        old_name = root.attrib.get(f'{android_ns}versionName')
        print(f"[*] 原 AndroidManifest.xml 版本: {old_name} (code: {old_code})")

        if version_code:
            root.attrib[f'{android_ns}versionCode'] = str(version_code)
        if version_name:
            root.attrib[f'{android_ns}versionName'] = str(version_name)

        axml.from_xml(root)
        updated_bytes = axml.pack()
        print(f"[✓] 已成功将 AndroidManifest.xml 版本更新为: {version_name} (code: {version_code})")
        return updated_bytes
    except Exception as e:
        print(f"[!] 警告: 更新 AndroidManifest.xml 失败或缺少 pyaxml 依赖: {e}")
        return manifest_bytes

def inject_resources_to_apk(base_apk, resource_dir, unsigned_apk, app_id="__UNI__CB17132", version_name=None, version_code=None):
    """解压基座 APK 并注入最新前端资源与更新版本号，剥离旧签名"""
    print(f"[*] 读取基础基座: {base_apk}")
    print(f"[*] 前端资源路径: {resource_dir}")

    # 规范化 resource_dir，找到包含 manifest.json 的根目录
    actual_res_dir = resource_dir
    if os.path.exists(os.path.join(resource_dir, 'www', 'manifest.json')):
        actual_res_dir = os.path.join(resource_dir, 'www')
    elif os.path.exists(os.path.join(resource_dir, 'manifest.json')):
        actual_res_dir = resource_dir
    else:
        for root, dirs, files in os.walk(resource_dir):
            if 'manifest.json' in files:
                actual_res_dir = root
                break

    print(f"[*] 实际资源基准路径: {actual_res_dir}")

    # 收集待注入的新资源相对路径
    new_files = {}
    for root, dirs, files in os.walk(actual_res_dir):
        for f in files:
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, actual_res_dir).replace('\\', '/')
            apk_path = f"assets/apps/{app_id}/www/{rel_path}"
            new_files[apk_path] = full_path

    print(f"[*] 收集到待更新/新增的前端文件: {len(new_files)} 个")

    target_prefix = f"assets/apps/{app_id}/www/"
    injected_count = 0
    preserved_count = 0
    stripped_meta = 0

    with zipfile.ZipFile(base_apk, 'r') as zin, zipfile.ZipFile(unsigned_apk, 'w', compression=zipfile.ZIP_DEFLATED) as zout:
        for item in zin.infolist():
            name = item.filename
            # 剥离旧的签名信息（META-INF/*）
            if name.startswith('META-INF/') and (
                name.endswith('.SF') or name.endswith('.RSA') or name.endswith('.DSA') or 
                name.endswith('.EC') or name.endswith('.MF')
            ):
                stripped_meta += 1
                continue

            # 处理 AndroidManifest.xml
            if name == 'AndroidManifest.xml' and (version_name or version_code):
                old_bytes = zin.read(name)
                new_bytes = update_manifest_version(old_bytes, version_name, version_code)
                zout.writestr(name, new_bytes)
                preserved_count += 1
                continue

            # 如果是前端 www 资源
            if name.startswith(target_prefix):
                if name in new_files:
                    with open(new_files[name], 'rb') as f_src:
                        zout.writestr(name, f_src.read())
                    injected_count += 1
                    del new_files[name]
                else:
                    content = zin.read(name)
                    zout.writestr(item, content)
                    preserved_count += 1
            else:
                content = zin.read(name)
                zout.writestr(item, content)
                preserved_count += 1

        # 将新增加的前端文件加入 APK
        for apk_path, local_path in new_files.items():
            with open(local_path, 'rb') as f_src:
                zout.writestr(apk_path, f_src.read())
            injected_count += 1

    print(f"[✓] 资源注入完成: 更新/写入 {injected_count} 个文件, 保留宿主原生文件 {preserved_count} 个, 剥离签名文件 {stripped_meta} 个")

def main():
    parser = argparse.ArgumentParser(description="uni-app 离线资源快速注入与自动签名打包工具")
    parser.add_argument("--base-apk", required=True, help="基础基座 APK 路径")
    parser.add_argument("--resource-dir", required=True, help="编译生成的最新前端资源目录")
    parser.add_argument("--keystore", required=True, help="Keystore 签名证书路径")
    parser.add_argument("--alias", default="youjuapp", help="证书别名 (默认: youjuapp)")
    parser.add_argument("--password", default="youjuapp2026", help="证书密码 (默认: youjuapp2026)")
    parser.add_argument("--app-id", default="__UNI__CB17132", help="DCloud AppID")
    parser.add_argument("--version-name", default=None, help="目标发布版本号，如 1.0.14")
    parser.add_argument("--version-code", default=None, help="目标数字版本码，如 1014")
    parser.add_argument("--output", required=True, help="最终输出签名 APK 路径")

    args = parser.parse_args()

    if not os.path.exists(args.base_apk):
        print(f"[!] 错误: 基座 APK 不存在: {args.base_apk}")
        sys.exit(1)
    if not os.path.exists(args.resource_dir):
        print(f"[!] 错误: 前端资源目录不存在: {args.resource_dir}")
        sys.exit(1)
    if not os.path.exists(args.keystore):
        print(f"[!] 错误: Keystore 文件不存在: {args.keystore}")
        sys.exit(1)

    work_dir = os.path.dirname(os.path.abspath(args.output)) or "."
    unsigned_apk = os.path.join(work_dir, "temp_unsigned.apk")
    aligned_apk = os.path.join(work_dir, "temp_aligned.apk")

    try:
        # 1. 注入资源并更新版本号
        inject_resources_to_apk(
            args.base_apk, 
            args.resource_dir, 
            unsigned_apk, 
            app_id=args.app_id, 
            version_name=args.version_name, 
            version_code=args.version_code
        )

        # 2. 寻找 zipalign
        zipalign_bin = find_android_tool("zipalign")
        if not zipalign_bin:
            print("[!] 警告: 未找到 zipalign，尝试直接用 unsigned.apk 进行签名...")
            aligned_apk = unsigned_apk
        else:
            print(f"[*] 找到 zipalign: {zipalign_bin}")
            align_cmd = [zipalign_bin, "-f", "-p", "4", unsigned_apk, aligned_apk]
            subprocess.check_call(align_cmd)
            print("[✓] 4 字节边界对齐完成 (zipalign)")

        # 3. 寻找 apksigner
        apksigner_bin = find_android_tool("apksigner")
        if not apksigner_bin:
            print("[!] 错误: 未找到 apksigner 工具，无法执行 V2/V3 签名！")
            sys.exit(1)

        print(f"[*] 找到 apksigner: {apksigner_bin}")
        sign_cmd = [
            apksigner_bin, "sign",
            "--ks", args.keystore,
            "--ks-key-alias", args.alias,
            "--ks-pass", f"pass:{args.password}",
            "--key-pass", f"pass:{args.password}",
            "--out", args.output,
            aligned_apk
        ]
        subprocess.check_call(sign_cmd)
        print(f"[✓] APK 签名完成: {args.output}")

        # 4. 校验签名
        verify_cmd = [apksigner_bin, "verify", "-v", args.output]
        res = subprocess.run(verify_cmd, capture_output=True, text=True)
        if res.returncode == 0:
            print("[✓] 签名验证成功:")
            for line in res.stdout.splitlines():
                if "Verified" in line or "Number of signers" in line:
                    print(f"    {line}")
        else:
            print(f"[!] 签名验证告警: {res.stderr or res.stdout}")

        file_size_mb = os.path.getsize(args.output) / (1024 * 1024)
        print(f"[🎉] 新 APK 成功构建！大小: {file_size_mb:.2f} MB")

    finally:
        if os.path.exists(unsigned_apk):
            os.remove(unsigned_apk)
        if os.path.exists(aligned_apk) and aligned_apk != unsigned_apk:
            os.remove(aligned_apk)

if __name__ == "__main__":
    main()
