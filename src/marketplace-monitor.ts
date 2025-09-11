import * as fcl from "@onflow/fcl";
import { config } from "@onflow/config";

// Configure FCL for mainnet
fcl.config()
  .put("accessNode.api", "https://rest-mainnet.onflow.org")
  .put("flow.network", "mainnet");

// Types for our event data
interface ListingDetails {
  listingResourceID: string;
  nftType: string;
  nftID: string;
  salePrice: string;
  seller: string;
  timestamp: number;
}

const DISNEY_PINNACLE_ADDRESS = "0xedf9df96c92f4595"; // DisneyPinnacle contract address
const NFT_STOREFRONT_ADDRESS = "0x4eb8a10cb9f87357"; // NFTStorefrontV2 contract address

export async function getLatestDisneyPinnacleListing(blockCount: number = 100): Promise<ListingDetails[]> {
  try {
    // Get the latest block height
    const latestBlock = await fcl.send([fcl.getBlock(true)]).then(fcl.decode);
    const endBlockHeight = latestBlock.height;
    const startBlockHeight = endBlockHeight - blockCount;

    // Event we want to monitor
    const listingEvent = `A.${NFT_STOREFRONT_ADDRESS.replace("0x", "")}.NFTStorefrontV2.ListingAvailable`;

    // Get events
    const events = await fcl.send([
      fcl.getEventsAtBlockHeightRange(
        listingEvent,
        startBlockHeight,
        endBlockHeight
      )
    ]).then(fcl.decode);

    // Log the first event to see its structure
    if (events.length > 0) {
      console.log("Sample event structure:", JSON.stringify(events[0], null, 2));
    }

    // Filter and format the events
    const listings: ListingDetails[] = events
      .filter((event: any) => {
        // Check if the NFT type contains DisneyPinnacle address
        const nftTypeString = String(event.data.nftType || '');
        return nftTypeString.includes(DISNEY_PINNACLE_ADDRESS);
      })
      .map((event: any) => ({
        listingResourceID: event.data.listingResourceID,
        nftType: event.data.nftType,
        nftID: event.data.nftID,
        salePrice: event.data.salePrice,
        seller: event.data.storefrontAddress,
        timestamp: event.data.timestamp || Date.now()
      }));

    return listings;
  } catch (error) {
    console.error("Error fetching DisneyPinnacle listings:", error);
    throw error;
  }
}

// Example usage
async function main() {
  try {
    const listings = await getLatestDisneyPinnacleListing(100);
    console.log("Latest DisneyPinnacle Listings:", JSON.stringify(listings, null, 2));
  } catch (error) {
    console.error("Error in main:", error);
  }
}

// Run the example if this file is executed directly
if (require.main === module) {
  main();
}
