import * as fs from "fs";
import * as path from "path";

export default (filename: string) =>
  JSON.parse(fs.readFileSync(path.join(__dirname, `../../../abis/${filename}`), { encoding: "utf8", flag: "r" }));
