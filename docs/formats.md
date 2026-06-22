# Formats

The NSZ application introduces three new file formats. Each is the zstd compressed version of their source files.

## NSZ

NSZ files are functionally identical to NSP files. The file extension difference is to alert the user that it contains compressed NCZ files. NCZ files can be mixed with NCA files in the same container.

As an alternative to this tool NSC_Builder also supports compressing NSP to NSZ and decompressing NSZ to NSP. NSC_Builder can be downloaded at <https://github.com/julesontheroad/NSC_BUILDER>.

## XCZ

XCZ files are functionally identical to XCI files. The file extension difference is to alert the user that it contains compressed NCZ files. NCZ files can be mixed with NCA files in the same container.

## NCZ

These are compressed NCA files. The NCAs are decrypted then compressed using zStandard.

The first 0x4000 bytes of a NCZ file is exactly the same as the original NCA (and still encrypted). This applies even if the first section doesn't start at 0x4000.

At 0x4000 there is the variable sized NCZ Header. It contains a list of sections which tell the decompressor how to re-encrypt the NCA data after decompression. It may also contain an optional block compression header allowing random read access.

All of the information in the header can be derived from the original NCA + Ticket, however it is provided pre-parsed to make decompression as easy as possible for third parties.

Directly after the NCZ header, the zStandard stream begins and ends at EOF. The stream is decompressed to offset 0x4000. If block compression is used the stream is split into independent blocks and can be decompressed as shown in <https://github.com/nicoboss/nsz/blob/master/nsz/BlockDecompressorReader.py>.

CompressedBlockSizeList[blockID] must not exceed decompressedBlockSize. If smaller: the block must be decompressed. If equal: the block is stored in plain text.

```python
class Section:
 def __init__(self, f):
  self.magic = f.read(8) # b'NCZSECTN'
  self.offset = f.readInt64()
  self.size = f.readInt64()
  self.cryptoType = f.readInt64()
  f.readInt64() # padding
  self.cryptoKey = f.read(16)
  self.cryptoCounter = f.read(16)

class Block:
 def __init__(self, f):
  self.magic = f.read(8) # b'NCZBLOCK'
  self.version = f.readInt8()
  self.type = f.readInt8()
  self.unused = f.readInt8()
  self.blockSizeExponent = f.readInt8()
  self.numberOfBlocks = f.readInt32()
  self.decompressedSize = f.readInt64()
  self.compressedBlockSizeList = []
  for i in range(self.numberOfBlocks):
   self.compressedBlockSizeList.append(f.readInt32())

nspf.seek(0x4000)
sectionCount = nspf.readInt64()
for i in range(sectionCount):
 sections.append(Section(nspf))

if blockCompression:
 BlockHeader = Block(nspf)
```