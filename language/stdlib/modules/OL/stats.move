
// This module returns statistics about the network at any given block, or window of blocks. A number of core OL modules depend on Statistics. The relevant statistics in an MVP are "liveness accountability" statistics. From within the VM context the statistics available are those in the BlockMetadata type.

address 0x0 {
  module Stats {
    use 0x0::Vector;
    use 0x0::Transaction;

    // Each Chunk represents one set of contiguous blocks which the validator voted on
    resource struct Chunk {
      start_block: u64,
      end_block: u64
    }

    // Each Node represents one validator
    resource struct Node {
      validator: address,
      chunks: vector<Chunk>
    }

    // This stores the full history. For POC, it is a vector which stores one
    //  entry for each validator.
    resource struct History {
      val_list: vector<Node>,
    }

    public fun initialize() {
      // Eventually want to ensue that only the Association and make a history block.
      // This should happen in genesis
      move_to_sender<History>(History{ val_list: Vector::empty() });
    }

    public fun newBlock(height: u64, votes: &vector<address>) acquires History {
      let i = 0;
      let len = Vector::length<address>(votes);

      while (i < len) {
        insert(*Vector::borrow(votes, i), height, height);
      };
    }

    public fun insert(node_addr: address, start_block: u64, end_block: u64) acquires History {
      let history = borrow_global_mut<History>(Transaction::sender());
      //let node_list = &mut history.val_list;

      // Add the a Node for the validator if one doesn't aleady exist
      if (!exists(history, node_addr)) {
        Vector::push_back(&mut history.val_list, Node{ validator: node_addr, chunks: Vector::empty() });
      };

      let node = get_node_mut(history, node_addr);
      let i = 0;
      let len = Vector::length<Chunk>(&node.chunks);

      if (len == 0) {
        Vector::push_back(&mut node.chunks, Chunk{ start_block: start_block, end_block: end_block });
        return
      };
      
      // This is a temporary reference to an existing chunk. Assuming there are no
      // conflicts and it is not adjacent to an existing chunk, it will be discarded.
      // If it is adjacent, we will assign this reference to the adjacent chunk so
      // we don't have to search for it again.
      // This should all be simpler in the final implementation in Rust since we will
      // be able to use binary trees and the Option<T> type.
      let adjacent = false;
      let chunk = Vector::borrow_mut(&mut node.chunks, 0);

      // Check to see if the insert conflicts with what is already stored
      while (i < len) {
        chunk = Vector::borrow_mut(&mut node.chunks, i);
        Transaction::assert(chunk.start_block > end_block, 1);
        Transaction::assert(chunk.end_block < start_block, 1);
        // If chunk.end_block == start_block, then we are just adding on to the last block
        if (chunk.end_block == start_block) {
          adjacent = true;
          break
        };
      };

      // Add in the new chunk
      if (adjacent){
        chunk.end_block = end_block
      } else {
        Vector::push_back(&mut node.chunks, Chunk{ start_block: start_block, end_block: end_block });
      }
    }

    // This should actually return a float as a percentage, but move doesn't support floats
    // as primitive types. For now, it will be returned as an unsigned int and be a confidence level 
    public fun Node_Heuristics(node_addr: address, start_height: u64, 
      end_height: u64): u64 acquires History {
      // Returns the percentage of blocks in the given range that the block voted on

      if (start_height > end_height) return 0;

      let history = borrow_global<History>(Transaction::sender());

      // This is the case where the validator has voted on nothing and does not have a Node
      if (!exists(history, node_addr)) return 0;

      let node = get_node(history, node_addr);
      let chunks = &node.chunks;
      let i = 0;
      let len = Vector::length<Chunk>(chunks);
      let num_voted = 0;

      // Go though all the chunks of the validator and accumulate
      while (i < len) {
        let chunk = Vector::borrow<Chunk>(chunks, i);
        // Check if the chunk has segments in desired region
        if (chunk.end_block > start_height && chunk.start_block < end_height) {
          // Find the lower and upper blockheights within desired region
          let lower = chunk.start_block;
          if (start_height > lower) lower = start_height;

          let upper = chunk.end_block;
          if (end_height < upper) upper = end_height;

          // +1 because bounds are inclusive.
          // E.g. a node which participated in only block 30 would have
          // upper - lower = 0 even though it voted in a block.
          num_voted = num_voted + (upper - lower + 1);
        }
      };
      num_voted 
      // This should be added to get a percentage: num_voted / (end_height - start_height + 1)
    }

    // This function goes through the vector in history and gets the desired node.
    // By the time this runs, we already know that the node exists in the history
    fun get_node(hist: &History, add: address): &Node {
      let i = 0;
      let node_list = &hist.val_list;
      let len = Vector::length<Node>(node_list);
      let node = Vector::borrow<Node>(node_list, i);

      while (i < len) {
        node = Vector::borrow<Node>(node_list, i);
        if (node.validator == add) break;
      };
      node
    }

    // This function goes through the vector in history and gets the desired node.
    // By the time this runs, we already know that the node exists in the history
    fun get_node_mut(hist: &mut History, add: address): &mut Node {
      let i = 0;
      let node_list = &mut hist.val_list;
      let len = Vector::length<Node>(node_list);
      let node = Vector::borrow_mut<Node>(node_list, i);

      while (i < len) {
        node = Vector::borrow_mut<Node>(node_list, i);
        if (node.validator == add) break;
      };
      node
    }

    // This must be included since does not suppot the Option<T> data type.
    // Since there is no way to return Some<Node> or None, we must do this check separately.
    fun exists(hist: &History, add: address): bool {
      let i = 0;
      let node_list = &hist.val_list;
      let len = Vector::length<Node>(node_list);

      while (i < len) {
        if (Vector::borrow<Node>(node_list, i).validator == add) return true;
      };
      false
    }


    // The actual Stats data structures and workings are a work in progress

    // TODO: Check if libra core "leader reputation" can be wrapped or implemented in our own contract: https://github.com/libra/libra/pull/3026/files
    // pub fun Node_Heuristics(node_address: address type, start_blockheight: u32, end_blockheight: u32)  {
    // fun liveness(node_address){
        // Returns the percentage of blocks have been signed by the node within the range of blocks.

        // Accomplished by querying the data structue
    // }

    // pub fun Network_Heuristics() {
    //  fun signer_density_window(start_blockheight, end_blockheight) {
        // Find the min count of nodes that signed *every* block in the range.
    //  }

    //  fun signer_density_lookback(number_of_blocks: u32 ) {
        // Sugar Needed for subsidy contract. Counts back from current block that accepted transaction. E.g. 1,000 blocks.
    //  }
    // }
  }
}


// Code which might be useful when moving beyond POC stage

//     struct TreeNode{
//       validator: address,
//       start_block: u32,
//       end_block: u32
//     }

//     resource struct Validator_Tree{
//       val_list: vector<u64>,    // not sure the type, so I leave it generic rn. Not the most robust
//       size: u64,              // number of blocks stored in this tree
//       root: TreeNode,
//     }
