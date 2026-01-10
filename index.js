/**
 * PolyBot - 钱包跟单机器人主入口
 */
import { PolymarketSDK } from '@catalyst-team/poly-sdk';
import config from './config.js';
import { WalletFollower } from './src/WalletFollower.js';

async function main() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║         PolyBot - 钱包跟单机器人          ║');
  console.log('╚════════════════════════════════════════════╝\n');

  let sdk = null;
  let follower = null;

  try {
    // 检查配置文件
    if (!config) {
      console.error('❌ 错误: 未找到配置文件');
      console.log('💡 提示: 请复制 config.example.js 为 config.js 并填入配置');
      process.exit(1);
    }

    // 初始化 poly-sdk
    console.log('🔧 初始化 poly-sdk...');
    
    // 如果需要交易功能，需要提供 privateKey
    if (config.sdk?.privateKey) {
      // 使用静态工厂方法（推荐）- 一行代码完成初始化
      sdk = await PolymarketSDK.create({
        privateKey: config.sdk.privateKey,
        chainId: config.sdk.chainId || 137, // Polygon 主网
      });
      console.log('✅ poly-sdk 初始化成功（交易模式）\n');
    } else {
      // 只读模式，无需认证
      sdk = new PolymarketSDK();
      console.log('✅ poly-sdk 初始化成功（只读模式）\n');
    }

    // 创建钱包跟单实例
    follower = new WalletFollower(sdk, config);

    // 如果配置了自动跟单，使用 SmartMoneyService 的自动跟单功能
    if (config.followSettings?.autoFollow && config.sdk?.privateKey) {
      console.log('\n🎯 使用自动跟单功能...\n');
      await follower.startAutoCopyTrading();
    } else {
      // 使用传统的手动监听方式
      await follower.initialize();

      if (config.followSettings?.autoFollow) {
        console.log('\n🎯 自动跟单已启用，开始监听...\n');
        await follower.startWatching();
      } else {
        console.log('\nℹ️  自动跟单已禁用（仅在配置中设置 followSettings.autoFollow = true 时启用）');
        console.log('💡 提示: 当前仅展示钱包信息，不会执行实际交易\n');
      }
    }

    // 处理优雅退出
    process.on('SIGINT', async () => {
      console.log('\n\n⚠️  接收到退出信号...');
      if (follower) {
        await follower.stop();
      }
      if (sdk) {
        sdk.stop();
      }
      console.log('👋 再见！');
      process.exit(0);
    });

    process.on('SIGTERM', async () => {
      console.log('\n\n⚠️  接收到终止信号...');
      if (follower) {
        await follower.stop();
      }
      if (sdk) {
        sdk.stop();
      }
      console.log('👋 再见！');
      process.exit(0);
    });

    // 保持程序运行
    console.log('⏳ 程序运行中... (按 Ctrl+C 退出)\n');
    
  } catch (error) {
    console.error('\n❌ 程序运行出错:', error);
    console.error(error.stack);
    if (sdk) {
      sdk.stop();
    }
    process.exit(1);
  }
}

// 运行主程序
main().catch(console.error);
